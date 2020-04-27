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
INCLUDEFILE="${SCRIPT_PATH}/backup-include"

# Where are we going to store the backup files?
BACKUPLOC="/backup/daily/"

# I also want to check the file size before and after the backup.
DUCMD="du -hs"

# Reference common script functions
source /opt/scripts/misc/common.sh

# Display the output to the screen and log file at the same time.
exec > >(tee "$LOGFILE") 2>&1

if [ -f "${INCLUDEFILE}" ]; then
	readarray -t SOURCES < "${INCLUDEFILE}"
else
	print_and_log "Daily Backup: No backup-include file found, using defaults." "DailyBackup" "error"
	SOURCES=(
		"/home/"
		"/media/Home Movies/"
		"/media/Pictures/"
		"/opt/"
		"/var/www/"
	)
fi

print_and_log "Daily Backup: Starting - $YEAR-$MONTH-$DAY $TIME" "DailyBackup" "info"

if [ ! -d "$BACKUPLOC" ]; then
	print_and_log "Daily Backup: Creating $BACKUPLOC" "DailyBackup" "info"
	mkdir -p "$BACKUPLOC"
fi

print_and_log "Original files:" "DailyBackup" "info"

$DUCMD "${SOURCES[@]}" # How to get this output into print_and_log?

print_and_log "Before rsync:" "DailyBackup" "info"

$DUCMD "${BACKUPLOC}" # How to get this output into print_and_log?

# Start the actual backup
for index in "${!SOURCES[@]}"; do
	TARGET="${BACKUPLOC}${SOURCES[index]}"
	# We get a // in the TARGET so lets remove it with regexp.
	# https://stackoverflow.com/questions/13043344/search-and-replace-in-bash-using-regular-expressions
	TARGET="${TARGET//\/\//\/}"

	rsync --archive --verbose --human-readable --progress \
	--delete --itemize-changes --delete-excluded \
	--owner --group --exclude-from="$EXCLUDEFILE" \
	"${SOURCES[index]}" "${TARGET}"

	# Check to see if rsync ran properly.
	# SC2181: Check exit code directly with e.g. 'if mycmd;', not indirectly with $?.
	# Not exactly sure what that means
	if [ $? -ne 0 ]; then
		print_and_log "Daily Backup: Rsync failed with exit code $?" "DailyBackup" "alert"
	else
		print_and_log "Daily Backup: Rsync complete for ${SOURCES[index]}" "DailyBackup" "info"
	fi
done

print_and_log "After rsync" "DailyBackup" "info"
$DUCMD "${BACKUPS[@]}"
du -chs "$BACKUPLOC" # How to get this output into print_and_log?

ENDTIME="$(date +%s)"

RUNTIME=$((ENDTIME-STARTTIME))

print_and_log "Daily Backup: Complete - Total runtime: $RUNTIME seconds." "DailyBackup" "debug"
print_and_log "Daily Backup: Detailed backup info:" "DailyBackup" "debug"
print_and_log "$LOGFILE" "DailyBackup" "debug"
