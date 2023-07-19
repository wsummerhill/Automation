#!/bin/bash
# Refs:
# http://stackoverflow.com/questions/11617210/how-to-properly-import-a-selfsigned-certificate-into-java-keystore-that-is-avail
# https://www.digitalocean.com/community/tutorials/how-to-secure-apache-with-let-s-encrypt-on-ubuntu-14-04
# http://www.advancedpentest.com/help-malleable-c2
# https://maximilian-boehm.com/hp2121/Create-a-Java-Keystore-JKS-from-Let-s-Encrypt-Certificates.htm

# Global Variables
runuser=$(whoami)
tempdir=$(pwd)

# Echo Title
clear
echo '=========================================================================='
echo ' HTTPS C2 Done Right Setup Script | [Updated]: 2023'
echo '=========================================================================='
echo ' [Web]: Http://CyberSyndicates.com | [Twitter]: @KillSwitch-GUI'
echo ' 2023 Updates By:'
echo ' [Web]: https://wsummerhill.github.io | [Twitter]: @BSummerz'
echo '=========================================================================='


echo -n "Enter your DNS (A) record for domain [ENTER]: "
read domain
echo

echo -n "Enter your common password to be used [ENTER]: "
read password
echo

# Input variables
domainPkcs="$domain.p12"
domainStore="$domain.store"


# Environment Checks
func_check_env(){
  # Check Sudo Dependency going to need that!
  if [ $(id -u) -ne '0' ]; then
    echo
    echo ' [ERROR]: This Setup Script Requires root privileges!'
    echo '          Please run this setup script again with sudo or run as login as root.'
    echo
    exit 1
  fi
}

func_check_tools(){
  if [ $(which keytool) ]; then
    echo '[Sweet] java keytool is installed'
  else
    echo
    echo ' [ERROR]: keytool does not seem to be installed'
    echo ' Install manually with: "sudo apt install openjdk-18-jre-headless -y"'
    exit 1
  fi
  if [ $(which openssl) ]; then
    echo '[Sweet] openssl keytool is installed'
  else
    echo
    echo ' [ERROR]: openssl does not seem to be installed'
    echo
    exit 1
  fi
  if [ $(which git) ]; then
    echo '[Sweet] git keytool is installed'
  else
    echo
    echo ' [ERROR]: git does not seem to be installed'
    echo
    exit 1
   fi
}

func_apache_check(){
  if [ $(which java) ]; then
    echo '[Sweet] java is already installed'
    echo
  else
    apt-get update
    apt-get install default-jre -y
    echo '[Success] java is now installed'
    echo
  fi
  
}

func_reinstall_certbot(){
  echo 'Removing old certbot version and installing new version with snapd'
  #apt remove certbot -y
  if [ $(which certbot) ]; then
	echo 'Certbot already installed'
  else
  	pip3 install certbot
  fi
  
  apt-get install python3-certbot-apache -y
  
  if [ $(which certbot) ]; then
  	echo '[Success] Certbot installed with pip!'
  else
  	echo '[ERROR] Certbot installation failed'
  	exit 1
  fi
}

func_install_letsencrypt(){
  echo '[Starting] cloning into letsencrypt!'
  git clone https://github.com/certbot/certbot /opt/letsencrypt
  echo '[Success] letsencrypt is built!'
  cd /opt/letsencrypt
  echo '[Starting] to build letsencrypt cert!'
  certbot certonly --apache -d $domain -n --register-unsafely-without-email --agree-tos 
  
  if [ -e /etc/letsencrypt/live/$domain/fullchain.pem ]; then
	echo '[Success] letsencrypt certs are built!'
  else
	echo "[ERROR] letsencrypt certs failed to build.  Check that DNS A record is properly configured \
    for this domain and that your local firewalls are open on ports 80 & 443!"
    	 exit 1
  fi
}

func_build_pkcs(){
  cd /etc/letsencrypt/live/$domain

  echo '[Starting] Building PKCS12 .p12 cert.'
  openssl pkcs12 -export -in fullchain.pem -inkey privkey.pem -out $domainPkcs -name $domain -passout pass:$password
  echo '[Success] Built $domainPkcs PKCS12 cert.'
  
  echo '[Starting] Building Java keystore via keytool.'
  keytool -importkeystore -deststorepass $password -destkeypass $password -destkeystore $domainStore -srckeystore $domainPkcs -srcstoretype PKCS12 -srcstorepass $password -alias $domain
  echo '[Success] Java keystore $domainStore built.'
  
  cp $domainStore /root
  cp cert.pem /root
  cp privkey.pem /root
  echo '[Success] Moved domain keystore, cert.pem, and privkey.pem to /root folder'
}


# Menu Case Statement
case $1 in
  *)
  func_check_env
  func_check_tools
  #func_apache_check
  func_reinstall_certbot
  func_install_letsencrypt
  func_build_pkcs
  ;;
esac
