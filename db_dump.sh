#!/bin/bash

echo "Nombre de la Base de Datos: "
read rootDir

httpDir="/var/www"

cd $httpDir/$rootDir;

FILE=$rootDir.`date +"%d-%m-%Y"`.sql
DBSERVER=localhost
DATABASE=$rootDir
USER=root
PASS=root

# mysqldump --opt --user=${USER} --password=${PASS} ${DATABASE} > ${FILE}
# mysqldump --opt --protocol=TCP --user=${USER} --password=${PASS} --host=${DBSERVER} ${DATABASE} > ${FILE}

if mysqldump --opt --user=${USER} --password=${PASS} ${DATABASE} > ${FILE}; then
  gzip $FILE
  echo "${FILE}.gz was created"
else
  echo "ERROR!!"
fi

notify-send "Finalizó la exportación de la base!"

echo -e "////////////////////////////////////////////////////"
echo -e "// Dump Completed"
echo -e "////////////////////////////////////////////////////"