#!/bin/bash

EMAIL="kaelan.ms@gmail.com"
USERNAME=k
DOTFILES_REPO="git@github.com:Oasixer/dotfiles.git"
SETUP_PROGRESS_DIR=/home/$USERNAME/temp/install_progress
BRANCH=debian
UDIR=/home/$USERNAME

# TODO install python versions, venv, flask, etc

step_gate () {
	TARGET=$1
	CHECK_FILE=$SETUP_PROGRESS_DIR/$TARGET
	shift
	if [ ! -f $CHECK_FILE ]; then
		echo "running setup/install step: $TARGET"
		eval "$1" && touch $CHECK_FILE
	else
		echo "skipping step: $TARGET"
	fi
}

setup_sudoers () {
	echo "\$run these commands as root"
	echo "adduser k sudo"
	echo "sudo apt-get install sudo -y"
	read -n 1 -p "press any letter to continue to su -"
	su -
	echo "reboot now"
	mkdir $SETUP_PROGRESS_DIR
	touch $SETUP_PROGRESS_DIR/sudo
	exit
}

install_apt_stuff () {
	apt update # after running this we know shit is updated
	apt install -y \
		vim \
		neovim \
		curl \
		nodejs \
		zsh \
		git \
		xclip \
		snapd \
		neofetch \
		autokey-gtk \
		g++ \
		libgtk-3-dev \
		libtool \
		gtk-doc-tools \
		gnutls-bin \
		valac \
		intltool \
		libpcre2-dev \
		libglib3.0-cil-dev \
		libgnutls28-dev \
		libgirepository1.0-dev \
		libxml2-utils \
		gperf \
		wget \
		mitmproxy \
		build-essential \
    apt-transport-https \
    ca-certificates \
    gnupg2 \
    software-properties-common
}

install_ohmyzsh () {
    sudo -u $USERNAME sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    sudo -u $USERNAME git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
}

install_chrome () {
	wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
	sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
	apt install google-chrome-stable -y
	apt remove firefox-esr -y
}

setup_git () {
	sudo -u $USERNAME ssh-keygen -t ed25519 -C $EMAIL
	eval "$(ssh-agent -s)"
	sudo -u $USERNAME ssh-add /home/$USERNAME/.ssh/id_ed25519
	sudo -u $USERNAME xclip -selection clipboard < /home/$USERNAME/.ssh/id_ed25519.pub
	sudo -u $USERNAME google-chrome-stable https://github.com/settings/ssh/new
	read -n 1 -p "press any letter to continue after adding ssh key to github"
}
setup_dotfiles () {
	cd /home/$USERNAME
  sudo -u $USERNAME git init
  sudo -u $USERNAME git remote add origin $DOTFILES_REPO
  sudo -u $USERNAME mkdir backup
  sudo -u $USERNAME mv .config/mimeapps.list backup_before_dotfiles_merge
  sudo -u $USERNAME mv .config/user-dirs.dirs backup_before_dotfiles_merge
  sudo -u $USERNAME mv .config/user-dirs.locale backup_before_dotfiles_merge
  sudo -u $USERNAME mv .zshrc backup_before_dotfiles_merge
	sudo -u $USERNAME git checkout $BRANCH
	sudo -u $USERNAME git submodule init
	sudo -u $USERNAME git submodule update
	sudo -u $USERNAME git pull
}

install_birame () {
    sudo -u $USERNAME git clone https://github.com/maniat1k/birame.git /home/$USERNAME/.oh-my-zsh/custom/themes/birame
    cp /home/$USERNAME/.oh-my-zsh/custom/themes/birame/birame.zsh-theme /home/$USERNAME/.oh-my-zsh/custom/themes/birame.zsh-theme
}

install_termite () {
	sudo -u $USERNAME git clone https://github.com/thestinger/vte-ng.git
	sudo -u $USERNAME echo export LIBRARY_PATH="/usr/include/gtk-3.0:$LIBRARY_PATH"

	cd vte-ng
	sudo -u $USERNAME ./autogen.sh
	sudo -u $USERNAME make
	make install
	sudo -u $USERNAME git clone --recursive https://github.com/thestinger/termite.git
	cd termite
	sudo -u $USERNAME make
	make install
	ldconfig
	mkdir -p /lib/terminfo/x
	ln -s /usr/local/share/terminfo/x/xterm-termite /lib/terminfo/x/xterm-termite
	update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/local/bin/termite 60

	exit
}

termite_style () {
	cd .config
	cd termite-style
	sudo -u $USERNAME ./install
	echo "Running termite-style. Choose theme=material, font=hack"
	sudo -u $USERNAME termite-style
}

install_snaps () {
    snap install discord
    snap install lotion
    snap install postman
    snap install slack --classic
}

install_fzf () {
    sudo -u $USERNAME git clone --depth 1 https://github.com/junegunn/fzf.git /home/$USERNAME/.fzf
    /home/$USERNAME/.fzf/install
}

install_spotify () {
    mkdir $UDIR/programs
    cd $UDIR/programs
    curl -sS https://download.spotify.com/debian/pubkey_0D811D58.gpg | apt-key add -
    echo "deb http://repository.spotify.com stable non-free" | tee /etc/apt/sources.list.d/spotify.list
    apt install spotify-client -y
}

install_docker () {
    apt-key fingerprint 0EBFCD88
    sudo -u $USERNAME curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
    
    apt-cache policy docker-ce
    apt-get install docker-ce docker-ce-cli containerd.io -y
    curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
    usermod -aG docker $USERNAME
}

install_yarn_flake () {
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    apt install yarn -y
    apt install flake8 -y
}

if [ ! -f $SETUP_PROGRESS_DIR/sudo ]; then
	setup_sudoers
else
	echo "skipping sudo"
fi

install_apt_stuff
step_gate ohmyzsh install_ohmyzsh
step_gate chrome install_chrome
step_gate git setup_git
step_gate dotfiles setup_dotfiles
step_gate birame install_birame
step_gate termite install_termite
step_gate termite_style termite_style
step_gate fzf install_fzf
step_gate spotify install_spotify
step_gate docker install_docker
step_gate yarn_flake install_yarn_flake
step_gate snaps install_snaps
