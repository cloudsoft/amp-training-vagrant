#!/bin/bash

# Exit script on error
set -e

# Set Java Vars
JAVA_VERSION=8
export JAVA_HOME=/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64/

echo "Download AMP"
curl -o cloudsoft-amp-karaf-all.deb -s -S http://download.cloudsoft.io/amp/4.latest/cloudsoft-amp-karaf-4.latest-all.deb
# curl -o cloudsoft-amp-karaf-all.deb -s -S http://downloads.cloudsoftcorp.com/amp/latest/cloudsoft-amp-karaf-latest-all.deb

echo "Validate downloaded file is an archive"
download_type=`file cloudsoft-amp-karaf-all.deb`

if ! (echo $download_type | grep 'Debian binary package') > /dev/null ; then
  cat >&2 <<EOL
ERROR - Downloaded AMP .deb is not a valid Debian binary package
ERROR - type: ${download_type}
ERROR -
EOL

  if grep -i unauthorized cloudsoft-amp-karaf-all.deb > /dev/null; then
    cat >&2 <<EOL
ERROR - The AMP download was unauthorized - please contact Cloudsoft support
ERROR - who will assist you further.
EOL
  elif grep -i "not found" cloudsoft-amp-karaf.tar.gz > /dev/null; then
    cat >&2 <<EOL
ERROR - The AMP download URL was invalid, please contact Cloudsoft support who will
ERROR - assist you further.
EOL
  fi
  exit 1
fi

echo "Restarting Syslog"
sudo systemctl restart rsyslog

echo "Install Java"
sudo apt-get install -y default-jre-headless

echo "Install AMP"
sudo dpkg -i cloudsoft-amp-karaf-all.deb

echo "Configure AMP Properties"
sudo mkdir -p /opt/amp/.brooklyn
sudo chown amp:amp /opt/amp/.brooklyn
sudo cp /vagrant/files/brooklyn.properties /opt/amp/.brooklyn/
sudo chown amp:amp /opt/amp/.brooklyn/brooklyn.properties
sudo chmod 600 /opt/amp/.brooklyn/brooklyn.properties

echo "Configure MOTD"
sudo cp /vagrant/files/motd /etc/motd

echo "Waiting for AMP to start..."
while ! (sudo grep "BundleEvent STARTED - org.apache.brooklyn.karaf-init" /opt/amp/log/amp.debug.log) > /dev/null ; do
  sleep 2
  echo ".... waiting for AMP to start at `date`"
done

# Restart AMP, so that brooklyn.properties takes effect
# (or could extract default username:password and use REST api)
echo "Restarting AMP..."
sudo systemctl restart amp

sudo systemctl restart rsyslog
sudo sh -c 'export DEBIAN_FRONTEND=noninteractive; apt-get install --yes python-pip shellinabox'
sudo sed -i '/SHELLINABOX_ARGS/c\SHELLINABOX_ARGS="--no-beep --disable-ssl"' /etc/default/shellinabox
sudo pip install tailon > /dev/null 2>&1

sudo chmod -R 777 /opt/amp/log
sudo ln -s /opt/amp/log/amp.info.log /vagrant/amp.info.log
sudo ln -s /opt/amp/log/amp.debug.log /vagrant/amp.debug.log
sudo ln -s /var/log/syslog /vagrant/syslog
sudo cp /vagrant/files/tailon.service /etc/systemd/system/tailon.service

sudo systemctl start tailon
sudo systemctl enable tailon
sudo systemctl restart shellinabox


