#!/usr/bin/env bash

# Credits:
# Partially based on https://github.com/wayneeseguin/rvm

shopt -s extglob  # Extend pattern matching

# --- Global Constants and Variables ---

angular_owner=ec2-user
angular_project_root_dir=~/repos/
display=1
screen=1
resolution="800x600x16"

# --- Functions ---

which_cmd() { which "$@" || return $?; true; }
phase_log() { printf "$(tput bold)$(tput setaf 1)$*$(tput sgr 0)\n"; }

check_for_root() {
  if [ ${EUID} != 0 ]
  then
    echo "Run this script with root using sudo..."
    exit
  fi
}

check_prerequisites() {
  check_for_root

  which_cmd wget > /dev/null || {
    echo "This script requires 'wget'. Please install 'wget' and try again."
    return 100
  }
}

install_packages() {
  
  sudo yum -y install firefox Xvfb libXfont Xorg 
  sudo yum -y groupinstall "X Window System" "Desktop" "Fonts" "General Purpose Desktop"

  # Install Xvfb.
  phase_log "Installing xvfb..."

  # yum search xvfb
  yum install -y xorg-x11-server-Xvfb

  #install the extra packages
  yum install epel-release
  
  #apt-get install -y xvfb x11-xkb-utils xfonts-100dpi \
  #xfonts-75dpi xfonts-scalable xfonts-cyrillic xserver-xorg-core dbus-x11 libfontconfig1-dev
  yum install libxml2-devel libxslt-devel zlib-devel python-devel

  # Install ruby (for compass)
  yum install -y ruby
  yum install -y rubygems
  
  # Install compass
  gem update --system
  gem install compass

  # Install other software.
  phase_log "Installing other software..."
  yum install -y ImageMagick gcc php unzip wget

  # Install node.js.
  phase_log "Installing node.js..."
  sudo yum install nodejs npm --enablerepo=epel
  #curl -sL https://rpm.nodesource.com/setup | bash -
  #yum install -y nodejs
  #yum install -y nodejs npm nodejs-legacy

  # Install (Google) chrome.
  phase_log "Installing (Google) chrome..."

  wget http://chrome.richardlloyd.org.uk/install_chrome.sh
  chmod u+x install_chrome.sh
  ./install_chrome.sh
  
  cat << 'EOF' > /etc/yum.repos.d/google-chrome.repo
[google-chrome]
name=google-chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/$basearch
enabled=1
gpgcheck=1
gpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub
EOF

#  chmod u+rw /etc/yum.repos.d/google-chrome.repo
#  yum install google-chrome-stable

  # Install chromedriver.
  phase_log "Installing chromedriver..."
  cd /usr/local/bin
  wget http://chromedriver.storage.googleapis.com/2.10/chromedriver_linux64.zip
  unzip chromedriver_linux64.zip
  mv chromedriver chromedriver-2.10
  rm chromedriver_linux64.zip
  ln -s chromedriver-2.10 chromedriver
  chmod +rx  chromedriver-2.10

  # Instll selenium.
  phase_log "Installing selenium..."
  useradd -m -s /bin/bash -d /home/selenium selenium
  mkdir -p /usr/local/lib/selenium
  chown -R selenium:selenium /usr/local/lib/selenium/
  mkdir -p /var/log/selenium
  chown -R selenium:selenium /var/log/selenium/
  cd /usr/local/lib/selenium
  sudo -u selenium wget http://selenium-release.storage.googleapis.com/2.42/selenium-server-standalone-2.42.2.jar
  sudo -u selenium ln -s selenium-server-standalone-2.42.2.jar selenium-server-standalone.jar
} 



install_angularjs() {
  if [[ -e $angular_project_root_dir ]]
  then
    cd $angular_project_root_dir/myapp
  else
    # Create an AngularJS project directory.
    phase_log "Installing an AngularJS directory..."
    sudo -u $angular_owner mkdir $angular_project_root_dir
    cd $angular_project_root_dir
    sudo -u $angular_owner git clone https://github.com/bassman5/MickAngularSeed.git myapp
    cd myapp
  fi

  # Install node modules.
  phase_log "Install node.js modules..."
  cd $angular_project_root_dir/myapp
  sudo -u $angular_owner npm install
  npm install -g bower grunt-cli
  npm install -g protractor
}

install_runlevel_scripts() {
  phase_log "Installing and configuring xvfb runlevel script..."
  cd /etc/init.d
  wget https://raw.githubusercontent.com/cybersamx/angularjs-testagent/master/xvfb
  sed -i "s/export\ DISPLAY\=\:1\.1/export\ DISPLAY\=\:$display\.$screen/" selenium
  chmod a+x xvfb
  update-rc.d xvfb defaults


  phase_log "Installing and configuring selenium runlevel script..."
  cd /etc/init.d
  wget https://raw.githubusercontent.com/cybersamx/angularjs-testagent/master/selenium
  sed -i "s/XVFB_ARGS=/XVFB_ARGS=\"\:$display -extension RANDR -noreset -ac -screen $screen $resolution\"/" xvfb
  chmod a+x selenium
  update-rc.d  selenium defaults
}

cleanup() {
  phase_log "Cleaning up after installation..."
}

start_services() {
  phase_log "Staring Xvfb service..."
  service xvfb start

  phase_log "Starting selenium service..."
  service selenium start
}

# -- Main Function ---

setup_testagent() {
  check_prerequisites
  install_packages
  install_angularjs
  install_runlevel_scripts
  cleanup
  start_services
}

setup_testagent "$@"
