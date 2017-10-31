#! /bin/bash

DAY="$(date +%d)"
MONTH="$(date +%m)"
YEAR="$(date +%Y)"
LOGLOC="/var/log/backup/daily"
LOGFILE="$LOGLOC/$YEAR/$MONTH/$YEAR.$MONTH.$DAY.log"
EXCLUDEFILE="/opt/backupscripts/backup-exclude"
BACKUPLOC="/backup/daily"

logger -p syslog.info "Starting Daily Backup - $YEAR-$MONTH-$DAY"

if [ ! -d "$LOGLOC/$YEAR/$MONTH/" ]; then
        echo "Creating $LOGLOC/$YEAR/$MONTH/"
        mkdir -p "$LOGLOC/$YEAR/$MONTH/"
fi

if [ ! -d "$BACKUPLOC" ]; then
        echo "Creating $BACKUPLOC"
        mkdir -p "$BACKUPLOC"
fi

exec > "$LOGFILE" 2>&1

echo "To: pasula.ubuntu@gmail.com"
echo "From: Backups <pasula.ubuntu@gmail.com>"
echo -e "Subject: Generated daily backup report for `hostname` on $YEAR.$MONTH.$DAY"
echo -e ">> Daily backup for: $YEAR.$MONTH.$DAY started @ `date +%H:%M:%S`n"

/opt/scripts/scriptheader.sh "Daily Backup"

echo "Original files:"
echo ""
sudo du -hs "/home/"
sudo du -hs "/media/Home Movies/"
sudo du -hs "/media/Pictures/"
sudo du -hs "/media/Youtube Videos/"
sudo du -hs "/opt/"
sudo du -hs "/var/www/"
echo ""

echo "Before rsync:"
echo ""
sudo du -hs "$BACKUPLOC/home/"
sudo du -hs "$BACKUPLOC/Home Movies/"
sudo du -hs "$BACKUPLOC/Pictures/"
sudo du -hs "$BACKUPLOC/Youtube Videos/"
sudo du -hs "$BACKUPLOC/opt"
sudo du -hs "$BACKUPLOC/var/www"
sudo du -chs "$BACKUPLOC/"
echo ""

# Question: How can I get these all on one line?
sudo rsync --archive --verbose --human-readable --progress --delete --itemize-changes --delete-excluded --exclude-from="$EXCLUDEFILE" "/home/" "$BACKUPLOC/home"
sudo rsync --archive --verbose --human-readable --progress --delete --itemize-changes --delete-excluded --exclude-from="$EXCLUDEFILE" "/media/Pictures/" "$BACKUPLOC/Pictures/"
sudo rsync --archive --verbose --human-readable --progress --delete --itemize-changes --delete-excluded --exclude-from="$EXCLUDEFILE" "/media/Home Movies/" "$BACKUPLOC/Home Movies/"
sudo rsync --archive --verbose --human-readable --progress --delete --itemize-changes --delete-excluded --exclude-from="$EXCLUDEFILE" "/media/Youtube Videos/" "$BACKUPLOC/Youtube Videos/"
sudo rsync --archive --verbose --human-readable --progress --delete --itemize-changes --delete-excluded --exclude-from="$EXCLUDEFILE" "/opt/" "$BACKUPLOC/opt/"
sudo rsync --archive --verbose --human-readable --progress --delete --itemize-changes --delete-excluded --exclude-from="$EXCLUDEFILE" "/var/www/" "$BACKUPLOC/var/www/"

echo ""
echo "After rsync"
echo ""
sudo du -hs "$BACKUPLOC/home/"
sudo du -hs "$BACKUPLOC/Home Movies/"
sudo du -hs "$BACKUPLOC/Pictures/"
sudo du -hs "$BACKUPLOC/Youtube Videos/"
sudo du -hs "$BACKUPLOC/opt"
sudo du -hs "$BACKUPLOC/var/www"
sudo du -chs "$BACKUPLOC/"
echo ""
df -h | grep "USB$"

# Display time stats
#SD=`echo -n "$SD" | grep real`
#MIN=`echo -n "$SD" | awk '{printf substr($2,0,2)}'`
#SEC=`echo -n "$SD" | awk '{printf substr($2,3)}'`
#echo -e "- done [ $MIN $SEC ].n"

/usr/sbin/sendmail -t < "$LOGFILE"
