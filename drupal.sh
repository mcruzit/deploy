#!/bin/bash

echo "Nombre del Directorio: "
read rootDir

echo "Nombre del Sitio: "
read siteName

echo "Slogan del Sitio: "
read siteSlogan

# Directories
##########################################################
httpDir="/var/www"
# rootDir=$1 #leave blank to set http directory as root directory.
var=$(pwd);
##########################################################
 
# Site
##########################################################
# siteName=$2
# siteSlogan=$3
# siteLocale="gb"
##########################################################

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

  unzip -d sites/all/libraries/ $var/ckeditor.zip
  unzip -d sites/all/modules/features/ $var/feature_initial_config.zip
  unzip -d sites/all/modules/features/ $var/feature_layout.zip
  unzip -d sites/all/modules/features/ $var/feature_widgets.zip

  # Download modules and themes
  ##########################################################
  cd sites/all/modules/contrib;

  drush -y en \
  admin_menu \
  admin_menu_source \
  backup_migrate \
  better_formats \
  boost \
  ctools \
  devel \
  embed_views \
  expire \
  features \
  field_ui \
  fieldable_panels_panes \
  field_collection \
  globalredirect \
  image \
  jquery_update \
  link \
  menu \
  menufield \
  metatag \
  panelizer \
  panels \
  panels_everywhere \
  pathauto \
  pm_existing_pages \
  redirect \
  transliteration \
  views \
  webform \
  wysiwyg \
  xmlsitemap \
  feature_initial_config \
  feature_layout \
  feature_widgets \
  adminimal_admin_menu \
  bootstrap;

  drush -y dl \
  adminimal_theme \
  google_analytics;

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
  drush vset -y node_admin_theme 1

  # Configure JQuery update 
  drush vset -y jquery_update_compression_type "min";
  drush vset -y jquery_update_jquery_cdn "google";

  drush generate-makefile drupal-org.make

  sudo chmod -R 777 /var/www/$rootDir/cache/
  sudo chmod -R 777 /var/www/$rootDir/sites/default/files/
  sudo chmod 444 /var/www/$rootDir/sites/default/settings.php

else

  cd $httpDir/$rootDir;
  drush make drupal-org.make -y

  FILE=$rootDir.`date +"%d-%m-%Y"`.sql
  DBSERVER=127.0.0.1
  DATABASE=$rootDir
  USER=root
  PASS=root

  if mysqldump --opt --user=${USER} --password=${PASS} ${DATABASE} > ${FILE}; then
    gzip $FILE
    echo "${FILE}.gz was created"
  else
    echo "ERROR!!"
  fi

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
