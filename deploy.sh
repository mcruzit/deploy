#!/bin/bash

function create {
  
  echo "Nombre del Directorio: "
  read rootDir

  echo "Nombre del Sitio: "
  read siteName

  echo "Slogan del Sitio: "
  read siteSlogan

  # Directories
  ##########################################################
  httpDir="/var/www"

  # Database
  ##########################################################
  dbHost="localhost"
  dbName=$rootDir
  dbUser="root"
  dbPassword="root"
  ##########################################################
   
  # Admin
  ##########################################################
  AdminUsername="root"
  AdminPassword="root"
  adminEmail="maximiliano.l.cruz@gmail.com"
  ##########################################################

  if [ ! -d "$httpDir/$rootDir" ]; then
   
    # Download Core
    ##########################################################
    drush dl -y --destination=$httpDir --drupal-project-rename=$rootDir;
     
    cd $httpDir/$rootDir;
     
    # Install core
    ##########################################################
    drush site-install -y minimal --account-mail=$adminEmail --account-name=$AdminUsername --account-pass=$AdminPassword --site-name="$siteName" --site-mail=$adminEmail --locale=es --db-url=mysql://$dbUser:$dbPassword@$dbHost/$dbName;

    mkdir sites/all/modules/contrib;
    mkdir sites/all/modules/features;

    # Download modules and themes
    ##########################################################
    cd sites/all/modules/contrib;

    drush -y en \
    admin_menu \
    admin_menu_source \
    backup_migrate \
    ctools \
    devel \
    features \
    field_ui \
    image \
    menu \
    transliteration \
    views \
    adminimal_admin_menu;

    drush -y dl \
    adminimal_theme;

    # Disable some core modules
    ##########################################################
    drush -y dis \
    dblog \
    block \
    update;

    drush -y pm-uninstall \
    dblog \
    block \
    update;
     
    # Pre configure settings
    ##########################################################
    # set site slogan
    drush vset -y site_slogan "$siteSlogan";

    # allow only admins to register users
    drush vset -y user_register 0;

    drush vset admin_theme adminimal;
    drush vset -y node_admin_theme 1;

    drush generate-makefile drupal-org.make

    sudo chmod -R 777 /var/www/$rootDir/cache/
    sudo chmod -R 777 /var/www/$rootDir/sites/default/files/
    sudo chmod 444 /var/www/$rootDir/sites/default/settings.php

  else

    echo "El directorio ya existe!";

  fi

}

function make {

  echo "Nombre del Directorio: "
  read rootDir

  # Directories
  ##########################################################
  httpDir="/var/www"

  cd $httpDir/$rootDir;
  drush make drupal-org.make -y

  FILE=$rootDir.`date +"%d-%m-%Y"`.sql
  DBSERVER=127.0.0.1
  DATABASE=$rootDir
  USER=root
  PASS=root

  if mysqldump --opt --user=${USER} --password=${PASS} ${DATABASE} > ${FILE}; then
    gzip -f $FILE
    echo "${FILE}.gz was created"
  else
    echo "ERROR!!"
  fi

}

if [ "$1" = "make" ]; then
  make
else
  create
fi

# Open the new website with Google Chrome
/usr/bin/google-chrome -a "http://localhost/$rootDir"

notify-send "Finalizó la instalación!"

echo -e "////////////////////////////////////////////////////"
echo -e "// Install Completed"
echo -e "////////////////////////////////////////////////////"
while true; do
  read -p "press enter to exit" yn
  case $yn in
    * ) exit;;
  esac
done
