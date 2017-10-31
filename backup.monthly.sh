#! /bin/bash

DAY="$(date +%d)"
MONTH="$(date +%m)"
YEAR="$(date +%Y)"

LOGLOC="/var/log/backup/monthly"
LOGFILE="$LOGLOC/$YEAR.$MONTH.$DAY.log"
BACKUPLOC="/backup/monthly"

logger -p syslog.info "Starting Monthly Backup - $YEAR-$MONTH-$DAY"

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
#echo -e "Subject: Generated monthly backup report for `hostname` on $YEAR.$MONTH.$DAY"
#echo -e ">> Monthly backup for: $YEAR.$MONTH.$DAY started @ `date +%H:%M:%S`n"

/opt/scripts/scriptheader.sh "Monthly Backup"

echo "Original files:"
echo ""
sudo du -hs "/backup/daily"
echo ""

echo "Before rsync:"
echo ""
sudo du -chs "/backup/monthly/"
echo ""

# Perform the backup and get time stats
SD=$( { time tar -cpPzf "$BACKUPLOC/$YEAR.$MONTH.$DAY.tar.gz" /backup/daily/; } 2>&1 )

# Display time stats
SD=`echo -n "$SD" | grep real`
MIN=`echo -n "$SD" | awk '{printf substr($2,0,2)}'`
SEC=`echo -n "$SD" | awk '{printf substr($2,3)}'`
echo -e "- done [ $MIN $SEC ].n"

echo ""
echo "After rsync"
sudo du -chs "/backup/monthly/"
echo ""

#/usr/sbin/sendmail -t < "$LOGFILE"
