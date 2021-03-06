#!/bin/bash

# Hostname setup
sudo hostnamectl set-hostname $HOSTNAME
sudo hostname $HOSTNAME
sudo sed -i 's/127.0.1.1.*/127.0.1.1\t'"$HOSTNAME"'/g' /etc/hosts

# Install Guest Additions
cd /tmp
sudo mkdir /tmp/isomount
sudo mount -t iso9660 -o loop $HOME/VBoxGuestAdditions.iso /tmp/isomount
sudo /tmp/isomount/VBoxLinuxAdditions.run
sudo umount isomount
sudo rm -rf isomount $HOME/VBoxGuestAdditions.iso

# Disable user `ubuntu` from showing up in login screen
echo -e "[User]\nSystemAccount=true" | sudo tee /var/lib/AccountsService/users/ubuntu

# Hack to get the hosts file to update
sudo hostnamectl set-hostname $HOSTNAME
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y build-essential libgtk2.0-0 libgconf2-4

# Install q2studio

sudo QIIME2_RELEASE=${QIIME2_RELEASE} bash <<'EOF'
  # Make sure PATH contains conda and the conda-installed npm and pip
  export PATH=/home/qiime2/miniconda/condabin:/home/qiime2/miniconda/envs/qiime2-${QIIME2_RELEASE}/bin:$PATH
  conda install -y -n qiime2-${QIIME2_RELEASE} gevent nodejs
  cd /opt/
  wget -O "q2studio-${QIIME2_RELEASE}.0.zip" "https://codeload.github.com/qiime2/q2studio/zip/${QIIME2_RELEASE}.0"
  unzip q2studio-${QIIME2_RELEASE}.0.zip
  rm q2studio-${QIIME2_RELEASE}.0.zip
  cd q2studio-${QIIME2_RELEASE}.0
  pip install .
  npm install -g npm@7.11.2
  # unsafe-perm is required in order for npm to write to /opt/q2studio
  npm install --unsafe-perm=true --legacy-peer-deps
  npm run build
  wget -O /usr/share/icons/hicolor/q2studio.png https://raw.githubusercontent.com/qiime2/logos/master/raster/white/qiime2-square-100.png
EOF

sudo cat <<EOF > /tmp/q2studio.desktop
[Desktop Entry]
Version=1.0
Exec=bash -c "/usr/bin/env PATH=/home/qiime2/miniconda/envs/qiime2-${QIIME2_RELEASE}/bin:$(echo '$PATH') npm start --prefix /opt/q2studio-${QIIME2_RELEASE}.0"
Name=q2studio
Icon=/usr/share/icons/hicolor/q2studio.png
GenericName=q2studio
Comment=QIIME 2 Studio
Encoding=UTF-8
Terminal=false
Type=Application
Categories=Application;
EOF

sudo mv /tmp/q2studio.desktop /usr/share/applications/q2studio.desktop

sudo su qiime2 <<'EOF'
  # Remove sudo banner warning
  touch $HOME/.sudo_as_admin_successful

  # Configure gnome launcher
  dbus-launch dconf write /org/gnome/shell/favorite-apps "['org.gnome.Terminal.desktop','q2studio.desktop','firefox.desktop','org.gnome.gedit.desktop','org.gnome.Nautilus.desktop']"

  # Disable `amazon` apps from showing up in the DE
  mkdir -p $HOME/.local/share/applications
  cp /usr/share/applications/ubuntu-amazon-default.desktop \
    $HOME/.local/share/applications/ubuntu-amazon-default.desktop
  echo "Hidden=true" >> $HOME/.local/share/applications/ubuntu-amazon-default.desktop
EOF
