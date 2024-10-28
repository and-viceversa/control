all: update install_software install_conda build_conda_env install_whonix install_kali

SHELL=/bin/bash
CONDA_ACTIVATE=source $$HOME/miniforge/etc/profile.d/conda.sh; conda activate; conda activate

APT = vagrant virtualbox virtualbox-ext-pack virtualbox-guest-x11 linux-headers-generic keepassxc wget curl debconf-utils

CONDA_URL = https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
CONDA_FILE = $$HOME/miniforge/miniforge.sh

.PHONY: update
update:
	# Update Ubuntu
	sudo apt -y update && sudo apt -y upgrade

.PHONY: register_vagrant
register_vagrant:
	wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg; \
	echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $$(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

.PHONY: install_software
install_software: register_vagrant
	# Install Software
	@echo virtualbox-ext-pack virtualbox-ext-pack/license select true | sudo debconf-set-selections
	sudo apt -y update && sudo apt -y install $(APT)
	sudo snap install pycharm-community --classic

.PHONY: install_conda
install_conda:
	# Install Conda
	mkdir -p $$HOME/miniforge; \
	if [ -e $(CONDA_FILE) ]; then \
		echo "Already downloaded"; \
	else \
		wget $(CONDA_URL) -O $(CONDA_FILE); \
	fi
	bash $(CONDA_FILE) -b -u -p $$HOME/miniforge
	@$(CONDA_ACTIVATE) base; \
	conda init --all; \
	conda update -q -y -n base -c conda-forge conda

.PHONY: conda_clean
conda_clean:
	# Clean existing conda env
	@-$(CONDA_ACTIVATE) base; \
	conda env remove -y -n collect

.PHONY: build_conda_env
build_conda_env: conda_clean
	# Build conda env
	@$(CONDA_ACTIVATE) base; \
	conda env create -y --file=environment.yml

.PHONY: install_whonix
install_whonix: install_software
	VBoxManage setextradata global GUI/SuppressMessages confirmGoingFullscreen,remindAboutMouseIntegration,remindAboutAutoCapture
	# Install Whonix VM
	curl --tlsv1.3 --output whonix-xfce-installer-cli --url https://www.whonix.org/dist-installer-cli
	printf '%s\n' N | bash ./whonix-xfce-installer-cli -n -k --allow-errors
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
	@$(CONDA_ACTIVATE) collect; \
	vagrant up
	#vagrant ssh -- -t 'sudo ip link set eth0 down; /bin/bash' &

.PHONY: conda_nuke
conda_nuke:
	# Nuke conda
	@$(CONDA_ACTIVATE) base; \
	conda init --reverse --all; \
	rm -rf anaconda3; \
	rm -rf $$HOME/anaconda3; \
	rm -rf $$HOME/opt/anaconda3; \
	rm -rf $$HOME/miniforge

.PHONY: vm_nuke
vm_nuke:
	# Nuke VMs
	VBoxManage controlvm Whonix-Gateway-Xfce poweroff; \
	VBoxManage controlvm Whonix-Workstation-Xfce poweroff; \
	VBoxManage controlvm kali_over_tor poweroff; \
	VBoxManage unregistervm Whonix-Gateway-Xfce --delete; \
	VBoxManage unregistervm Whonix-Workstation-Xfce --delete; \
	VBoxManage unregistervm kali_over_tor --delete

.PHONY: clean
clean: conda_nuke vm_nuke vm_nuke
	# Made clean
