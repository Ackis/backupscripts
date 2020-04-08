#! /bin/bash

# Checks to see if the current user is root.
# If it's not root, the script restarts itself through sudo.
[[ $UID = 0 ]] || exec sudo "$0"

# Script Variables
# When is the script being run?
# I also want to name the logs individually based on date.
# There's probably an easier/faster way to do this.
TIME="$(date +%T)"
DAY="$(date +%d)"
MONTH="$(date +%m)"
YEAR="$(date +%Y)"

# Internal script variables
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Track the script time - I want to see how long it takes to run.
STARTTIME="$(date +%s)"

# Where are we going to store the log files?
LOGFILE="/var/log/backup/daily/$YEAR-$MONTH-$DAY.log"

# List of files that we don't want to backup.
EXCLUDEFILE="${SCRIPT_PATH}/backup-exclude"

# List of directories that we want to backup.
INCLUDEFILE="${SCRIPT_PATH}/backup-includef"

# Where are we going to store the backup files?
BACKUPLOC="/backup/daily/"

# I also want to check the file size before and after the backup.
DUCMD="du -hs"

if [ -f "INCLUDEFILE" ]; then
	readarray -t SOURCES < "INCLUDEFILE"
else
	SOURCES=(
		"/home/"
		"/media/Home Movies/"
		"/media/Pictures/"
		"/opt/"
		"/var/www"
	)
fi

BACKUPS=(
	"$BACKUPLOC/home/"
	"$BACKUPLOC/Home Movies/"
	"$BACKUPLOC/Pictures/"
	"$BACKUPLOC/opt"
	"$BACKUPLOC/var/www"
)

# Display the output to the screen and log file at the same time.
exec > >(tee "$LOGFILE") 2>&1

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
