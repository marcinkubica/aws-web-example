#!/bin/bash
CREDFILE="./aws_creds.sh"

if [ ! -f /etc/centos-release ]; then echo "Please run me under Centos. Exiting."; exit 1; fi

echo "Installing packages for yor buildbox."
PKGS="epel-release ansible python-boto python-boto3"

for p in $PKGS; do

    sudo yum -y install $p

done

echo -e "\nPlease note AWS region in inv/ec2.ini was set to us-east-1 \nin order to speed up the dynamic inventory script execution."

echo -e "\nChecking ssh key in your user folder and creating one if missing."

if [ ! -f ~/.ssh/id_rsa ]; 
 then 
      ssh-keygen -f id_rsa -t rsa -N ''; 
 else 
      echo "SSH id key found. Skipping."; 
fi

echo -e "\nPlease update $CREDFILE and run: \n\nsource $CREDFILE \n"


