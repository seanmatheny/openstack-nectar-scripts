#encrypt and backup file to shared drobbox folder
#EMAIL any standard error output
#TODO: trim oldest copied in Dropbox
ERRFILE=/tmp/backup_db_errors.tmp
EMAIL='alerts@xxx.com'
PASSPHRASE='xxx'
APIKEY='xxx'

#do the backup
cd /var/lib/backup/mysql
for i in $(find . -type f)
do
  #echo ${i:2}
  /usr/bin/gpg -c --passphrase $PASSPHRASE --batch --no-use-agent ${i}
  GPGFILE="${i:2}.gpg"
  echo $GPGFILE
  /usr/bin/curl -X POST https://content.dropboxapi.com/2/files/upload --header "Authorization: Bearer ${APIKEY}" --header "Dropbox-API-Arg: {\"path\": \"/${GPGFILE}\"}" --header "Content-Type: application/octet-stream" --data-binary @${GPGFILE} 2>
  rm ${GPGFILE}
done

#send EMAIL with errors, if there were any
if [ -s ${ERRFILE} ]
  then
    echo "errors"
    cat ${ERRFILE} | /usr/bin/mail -s "There were errors running the Nova DB Offsite Backup Job on ntr-db01" ${EMAIL}
    rm -f ${ERRFILE}
  else
    echo "no errors"
    rm -f ${ERRFILE}
fi
