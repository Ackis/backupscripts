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

LOGFILE="/var/log/backup/weekly/$YEAR-$MONTH-$DAY.log"

EXCLUDEFILE="/opt/scripts/backupscripts/backup-exclude"
BACKUPLOC="/backup/weekly"

DUCMD="du -hs"

SOURCES=(
	"/backup/daily/"
)

BACKUPS=(
	"$BACKUPLOC/"
)

logger -t WeeklyBackup -p syslog.notice "Weekly Backup: Starting - $YEAR-$MONTH-$DAY $TIME"

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
	--exclude-from="$EXCLUDEFILE" \
	"${SOURCES[index]}" "${BACKUPS[index]}"

	if [ $? -ne 0 ]; then
		logger -t WeeklyBackup -p syslog.alert "Weekly Backup: Rsync failed with exit code $?"
	else
		logger -t WeeklyBackup -p syslog.info "Weekly Backup: Rsync complete for ${SOURCES[index]}"
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

logger -t WeeklyBackup -p syslog.notice "Weekly Backup: Complete - Total runtime: $RUNTIME seconds."
#logger -t WeeklyBackupDetails -p syslog.debug "Weekly Backup: Detailed backup info:"
#logger -t WeeklyBackupDetails -p syslog.debug -f "$LOGFILE"
