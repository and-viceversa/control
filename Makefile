all: update install_software install_conda build_conda_env install_whonix install_kali

SHELL=/bin/bash
CONDA_ACTIVATE=source ~/miniconda3/etc/profile.d/conda.sh ; conda activate ; conda activate

WHONIX_URL = https://download.whonix.org/ova/17.1.3.1/
WHONIX_FILE = Whonix-Xfce-17.1.3.1.ova

CONDA_URL = https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
CONDA_FILE = ~/miniconda3/miniconda.sh

.PHONY: update
update:
	# Update Ubuntu
	sudo apt update && sudo apt -y upgrade

.PHONY: install_software
install_software:
	# Install Software
	sudo apt -y install vagrant virtualbox virtualbox-ext-pack virtualbox-guest-x11 keepassxc wget
	sudo snap install pycharm-community --classic

.PHONY: install_conda
install_conda:
	# Install Conda
	mkdir -p ~/miniconda3 ; \
	if [ -e $(CONDA_FILE) ]; then \
		echo "Already downloaded"; \
	else \
		wget $(CONDA_URL) -O $(CONDA_FILE) ; \
	fi
	bash $(CONDA_FILE) -b -u -p ~/miniconda3 ; \
	# rm -rf ~/miniconda3/miniconda.sh
	~/miniconda3/bin/conda init bash
	~/miniconda3/bin/conda init zsh

.PHONY: conda_clean
conda_clean:
	# Clean existing conda env
	@$(CONDA_ACTIVATE) base ; \
	conda env remove -y -n collect

.PHONY: build_conda_env
build_conda_env: conda_clean
	# Build conda env
	@$(CONDA_ACTIVATE) base ; \
	conda env create -y -f environment.yml

.PHONY: install_whonix
install_whonix: install_software
	VBoxManage setextradata global GUI/SuppressMessages confirmGoingFullscreen,remindAboutMouseIntegration,remindAboutAutoCapture
	# Install Whonix VM
	if [ -e $(WHONIX_FILE) ]; then \
		echo "Already downloaded"; \
	else \
		wget $(WHONIX_URL)$(WHONIX_FILE); \
	fi
	VBoxManage import Whonix-Xfce-17.1.3.1.ova --vsys 0 --eula=accept --vsys 1 --eula=accept
	# Disable Audio
	VBoxManage modifyvm Whonix-Gateway-Xfce --audio none
	VBoxManage modifyvm Whonix-Workstation-Xfce --audio none
	VBoxManage modifyvm Whonix-Gateway-Xfce --audioin off
	VBoxManage modifyvm Whonix-Workstation-Xfce --audioin off
	VBoxManage modifyvm Whonix-Gateway-Xfce --audioout off
	VBoxManage modifyvm Whonix-Workstation-Xfce --audioout off
	# Disable clipboard and file transfers
	VBoxManage modifyvm Whonix-Gateway-Xfce --clipboard-mode disabled
	VBoxManage modifyvm Whonix-Workstation-Xfce --clipboard-mode disabled
	VBoxManage modifyvm Whonix-Gateway-Xfce --draganddrop disabled
	VBoxManage modifyvm Whonix-Workstation-Xfce --draganddrop disabled
	# Configure Whonix Gateway Networking
	VBoxManage modifyvm Whonix-Gateway-Xfce --nic1 nat
	VBoxManage modifyvm Whonix-Gateway-Xfce --intnet2 "Whonix"
	# Configure Whonix Workstation Networking
	VBoxManage modifyvm Whonix-Workstation-Xfce --intnet1 "Whonix"
	# Start the Whonix VMs
	VBoxManage startvm Whonix-Gateway-Xfce
	VBoxManage startvm Whonix-Workstation-Xfce
	read -p "Configure Whonix Then Press Enter to Continue: " enter; \

.PHONY: install_kali
install_kali: install_software install_conda build_conda_env
	# Install Kali VM
	@$(CONDA_ACTIVATE) collect ; \
	vagrant up
	#vagrant ssh -- -t 'sudo ip link set eth0 down; /bin/bash' &

.PHONY: conda_nuke
conda_nuke:
	# Nuke conda
	@$(CONDA_ACTIVATE) base ; \
	conda init --reverse --all ; \
	rm -rf anaconda3 ; \
	rm -rf ~/anaconda3 ; \
	rm -rf ~/opt/anaconda3 ; \
	rm -rf ~/miniconda3

.PHONY: vm_nuke
vm_nuke:
	# Nuke VMs
	VBoxManage controlvm Whonix-Gateway-Xfce poweroff ; \
	VBoxManage controlvm Whonix-Workstation-Xfce poweroff ; \
	VBoxManage controlvm kali_over_tor poweroff ; \
	VBoxManage unregistervm Whonix-Gateway-Xfce --delete ; \
	VBoxManage unregistervm Whonix-Workstation-Xfce --delete ; \
	VBoxManage unregistervm kali_over_tor --delete

.PHONY: clean
clean: conda_nuke vm_nuke vm_nuke
	# Made clean
