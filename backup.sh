#! /bin/bash

# Checks to see if the current user is root.
# If it's not root, the script restarts itself through sudo.
[[ $UID = 0 ]] || exec sudo "$0"

# Script Variables
TIME="$(date +%T)"
DAY="$(date +%d)"
MONTH="$(date +%m)"
YEAR="$(date +%Y)"

# Track the script time
STARTTIME="$(date +%s)"

LOGFILE="/var/log/backup/daily/$YEAR-$MONTH-$DAY.log"

EXCLUDEFILE="/opt/scripts/backupscripts/backup-exclude"
BACKUPLOC="/backup/daily"

DUCMD="du -hs"

SOURCES=(
	"/home/"
	"/media/Home Movies/"
	"/media/Pictures/"
	"/media/Youtube Videos/"
	"/opt/"
	"/var/www"
)

BACKUPS=(
	"$BACKUPLOC/home/"
	"$BACKUPLOC/Home Movies/"
	"$BACKUPLOC/Pictures/"
	"$BACKUPLOC/Youtube Videos/"
	"$BACKUPLOC/opt"
	"$BACKUPLOC/var/www"
)

logger -t DailyBackup -p syslog.notice "Daily Backup: Starting - $YEAR-$MONTH-$DAY $TIME"

if [ ! -d "$BACKUPLOC" ]; then
        echo "Creating $BACKUPLOC"
        mkdir -p "$BACKUPLOC"
fi

exec > "$LOGFILE" 2>&1

echo "Original files:"
echo ""

$DUCMD "${SOURCES[@]}"

echo "Before rsync:"
echo ""

$DUCMD "${BACKUPS[@]}"

echo ""

for index in "${!SOURCES[@]}"; do
	rsync --archive --verbose --human-readable --progress \
	--delete --itemize-changes --delete-excluded \
	--owner --group --exclude-from="$EXCLUDEFILE" \
	"${SOURCES[index]}" "${BACKUPS[index]}"

	if [ $? -ne 0 ]; then
		logger -t DailyBackup -p syslog.alert "Daily Backup: Rsync failed with exit code $?"
	else
		logger -t DailyBackup -p syslog.info "Daily Backup: Rsync complete for ${SOURCES[index]}"
	fi
done

echo ""
echo "After rsync"
echo ""
$DUCMD "${BACKUPS[@]}"

echo ""
du -chs "$BACKUPLOC"
df -h | grep "USB$"

ENDTIME="$(date +%s)"

RUNTIME=$((ENDTIME-STARTTIME))

logger -t DailyBackup -p syslog.notice "Daily Backup: Complete - Total runtime: $RUNTIME seconds."
logger -t DailyBackupDetails -p syslog.debug "Daily Backup: Detailed backup info:"
logger -t DailyBackupDetails -p syslog.debug -f "$LOGFILE"
#rm "$LOGFILE"
