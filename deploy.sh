#!/bin/bash

# Take default variables from environment.conf file
source $(dirname "$(readlink -f $0)")/environment.conf

function dp_create {
  
  echo "Nombre del Directorio: "
  read rootDir

  echo "Nombre del Sitio: "
  read siteName

  echo "Slogan del Sitio: "
  read siteSlogan

  # Database
  ##########################################################
  dbName=$rootDir
  ##########################################################

  if [ ! -d "$httpDir/$rootDir" ]; then
   
    # Download Core
    ##########################################################
    drush dl -y --destination=$httpDir --drupal-project-rename=$rootDir;
     
    cd $httpDir/$rootDir;

    mkdir sites/all/modules/contrib;
    mkdir sites/all/modules/features;

    unzip -d sites/all/libraries/ $DP_SOURCES/ckeditor.zip
    unzip -d sites/all/modules/features/ $DP_SOURCES/feature_initial_config.zip
    unzip -d sites/all/modules/features/ $DP_SOURCES/feature_layout.zip
    unzip -d sites/all/themes/ $DP_SOURCES/name_theme.zip

    # Rename Name of the folder, files and info of Feature Layout
    cd sites/all/modules/features/;
    rename "s/feature_layout/feature_$rootDir_layout/" *
    cd feature_$rootDir_layout/;
    rename "s/feature_layout/feature_$rootDir_layout/" *
    sed -i 's/feature_layout/feature_$rootDir_layout/g' *.module
    sed -i 's/Layout Feature/$siteName Layout Feature/g' *.info
    sed -i 's/Maximiliano Cruz/$siteName/g' *.info

    # Rename Name of the folder, files and info of Custom Theme
    # cd $httpDir/$rootDir/sites/all/themes/;
    # rename "s/name_theme/$rootDir_theme/" *
    # cd "$rootDir_theme/";
    # rename "s/name_theme/$rootDir_theme/" *.info
    # sed -i 's/NAME/$siteName/g' *.info
    # sed -i 's/name/$rootDir/g' *.php
    
    # Install core
    ##########################################################
    drush site-install -y minimal --account-mail=$adminEmail --account-name=$AdminUsername --account-pass=$AdminPassword --site-name="$siteName" --site-mail=$adminEmail --locale=es --db-url=mysql://$dbUser:$dbPassword@$dbHost/$dbName;

    # Download modules and themes
    ##########################################################
    cd sites/all/modules/contrib;

    drush -y en \
    admin_menu \
    admin_menu_source \
    adminimal_admin_menu \
    backup_migrate \
    better_formats \
    boost \
    ctools \
    devel \
    expire \
    features \
    feature_initial_config \
    field_ui \
    fieldable_panels_panes \
    globalredirect \
    image \
    jquery_update \
    link \
    menu \
    metatag \
    panels \
    panels_everywhere \
    pathauto \
    redirect \
    transliteration \
    views \
    webform \
    wysiwyg \
    xmlsitemap;

    drush dl \
    google_analytics \
    adminimal_theme \
    bootstrap;

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

    cd "/var/www/";
    ln -s $httpDir/$rootDir;

    # Open the new website with Google Chrome
    /usr/bin/google-chrome -a "http://localhost/$rootDir/user"

    notify-send "Finalizó la instalación!"

    echo -e "////////////////////////////////////////////////////"
    echo -e "// Install Completed"
    echo -e "////////////////////////////////////////////////////"
    exit;

  else

    echo "El directorio ya existe!";

  fi

}

function dp_make {

  echo "Nombre del Directorio: "
  read rootDir

  # Directories
  ##########################################################
  httpDir="/var/www"

  cd $httpDir/$rootDir;
  drush make drupal-org.make -y

  FILE=$rootDir.`date +"%d-%m-%Y"`.sql
  DATABASE=$rootDir

  if mysqldump --opt --user=${dbUser} --password=${dbPassword} ${DATABASE} > ${FILE}; then
    gzip -f $FILE
    echo "${FILE}.gz was created"
  else
    echo "ERROR!!"
  fi

}

function dp_generateMakeFile {
  echo "Nombre del Directorio: "
  read rootDir

  httpDir="/var/www"

  cd $httpDir/$rootDir;

  drush generate-makefile drupal-org.make
}

# Wordpress
##########################################################

function wp_create {

  echo "Dir Name: "
  read rootDir

  # accept the name of our website
  echo "Site Name: "
  read -e sitename

  # add a simple yes/no confirmation before we proceed
  echo "Run Install? (y/n)"
  read -e run

  # Database
  ##########################################################
  dbName=$rootDir

  # if the user didn't say no, then go ahead an install
  if [ "$run" == n ] ; then
  exit
  else

  # download the WordPress core files
  wp core download --path=$httpDir/$rootDir --locale=es_ES

  # Create virtualhost
  echo "Create VirtualHost? Insert the user password"
  sudo virtualhost create $rootDir.dev $httpDir/$rootDir/

  cd $httpDir/$rootDir;

  # Create file .htaccess
  cat > .htaccess <<EOF

# BEGIN WordPress
<IfModule mod_rewrite.c>

RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>

# END WordPress
EOF

  # create the wp-config file
  wp core config --dbname=$dbName --dbuser=$dbUser --dbpass=$dbPassword --extra-php <<PHP
define( 'WP_DEBUG', true );
define( 'DISALLOW_FILE_EDIT', true );
PHP

  # create database, and install WordPress
  wp db create
  wp core install --url="http://$rootDir.dev" --title="$sitename" --admin_user="$AdminUsername" --admin_password="$AdminPassword" --admin_email="$adminEmail" --skip-email

  # Update Blog Description
  wp option update blogdescription ""
  # Update Timezone
  wp option update timezone_string "America/Argentina/Buenos_Aires"
  # Update Date Format
  wp option update date_format "d/m/Y"
  # Update Time Format
  wp option update time_format "H:i"
  # Update Start of Week
  wp option update start_of_week 0
  # Update Comments Settings
  wp option update default_pingback_flag 0
  wp option update default_ping_status 0
  wp option update default_comment_status 0
  wp option update comment_registration 1
  wp option update comment_moderation 1

  # delete sample page
  wp post delete $(wp post list --post_type=page --posts_per_page=1 --post_status=publish --pagename="pagina-ejemplo" --field=ID --format=ids) && wp post delete $(wp post list --post_type=page --posts_per_page=1 --post_status=trash --pagename="pagina-ejemplo__trashed" --field=ID --format=ids)
  wp post delete $(wp post list --post_type=post --posts_per_page=1 --post_status=publish --post_name="hello-world" --field=ID --format=ids) && wp post delete $(wp post list --post_type=post --posts_per_page=1 --post_status=trash --post_name="hello-world" --field=ID --format=ids)

  # set pretty urls
  wp rewrite structure '/%postname%/' --hard
  wp rewrite flush --hard

  # delete akismet and hello dolly
  wp plugin delete akismet
  wp plugin delete hello

  # create a navigation bar
  wp menu create "Main Menu"

  # assign navigaiton to primary location
  wp menu location assign main-menu primary

  # install the _s theme
  wp theme install bootstrap-basic

  clear;

  # Open the new website with Google Chrome
  /usr/bin/google-chrome -a "http://$rootDir.dev/wp-login.php"

  notify-send "Finalizó la instalación!"

  echo -e "////////////////////////////////////////////////////"
  echo -e "// Installation Completed"
  echo -e "////////////////////////////////////////////////////"
  exit;

  fi

}

fname=`declare -f -F $1`

if [ ! -z $1 ] && [ -n "$fname" ]; then
  $1
else
  echo "The function does not exist.";
  echo "Existing functions: ";
  compgen -A function

  exit;
fi