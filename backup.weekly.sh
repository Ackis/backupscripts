#! /bin/bash
DAY="$(date +%d)"
MONTH="$(date +%m)"
YEAR="$(date +%Y)"
LOGLOC="/var/log/backup/weekly"
LOGFILE="$LOGLOC/$YEAR/$MONTH/$YEAR.$MONTH.$DAY.log"
EXCLUDEFILE="/opt/backupscripts/backup-exclude"
BACKUPLOC="/backup/weekly"

logger -p syslog.info "Starting Weekly Backup - $YEAR-$MONTH-$DAY"

if [ ! -d "$LOGLOC/$YEAR/$MONTH/" ]; then
	echo "Creating $LOGLOC/$YEAR/$MONTH/"
	mkdir -p "$LOGLOC/$YEAR/$MONTH/"
fi

if [ ! -d "$BACKUPLOC" ]; then
	echo "Creating $BACKUPLOC"
	mkdir -p "$BACKUPLOC"
fi

exec > "$LOGFILE" 2>&1

#echo "To: pasula.ubuntu@gmail.com"
#echo "From: Backups <pasula.ubuntu@gmail.com>"
#echo -e "Subject: Generated weekly backup report for `hostname` on $YEAR.$MONTH.$DAY"
#echo -e ">> Weekly backup for: $YEAR.$MONTH.$DAY started @ `date +%H:%M:%S`n"


/opt/scripts/scriptheader.sh "Weekly Backup"

echo "Original files:"
sudo du -chs /backup/daily/
echo ""

echo "Before rsync:"
echo ""
sudo du -chs "/backup/weekly/"
echo ""

sudo rsync --archive --verbose --human-readable --progress --delete --itemize-changes --delete-excluded --exclude-from="$EXCLUDEFILE" /backup/daily/ "$BACKUPLOC"

echo ""
echo "After rsync"
sudo du -chs "/backup/weekly/"
echo ""

# Display time stats
#SD=`echo -n "$SD" | grep real`
#MIN=`echo -n "$SD" | awk '{printf substr($2,0,2)}'`
#SEC=`echo -n "$SD" | awk '{printf substr($2,3)}'`
#echo -e "- done [ $MIN $SEC ].n"

#/usr/sbin/sendmail -t < "$LOGFILE"
