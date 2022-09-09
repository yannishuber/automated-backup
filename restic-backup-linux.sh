#!/bin/bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    ${SCRIPT_NAME}
#%
#% DESCRIPTION
#%    Script which automates backups using restic 
#%    and stores them encrypted on Infomaniak Swiss Backup.
#%    Adapted from: https://szymonkrajewski.pl/macos-backup-restic/
#%
#================================================================
#- IMPLEMENTATION
#-    version         ${SCRIPT_NAME} 1.0.0
#-    author          Yannis HUBER, Nicolas FEYER
#-    license         GNU General Public License
#-
#================================================================
#  HISTORY
#     2015/03/01 : Nicolas FEYER : Adapt script for Linux/Debian
#     1022/01/18 : Yannis HUBER  : Create script for MacOS
#
#================================================================
# END_OF_HEADER
#================================================================

# Load configuration
source /home/nicolas/.restic-config

PID_FILE=/home/nicolas/.restic_backup.pid # used to know if the scrip is running
TIMESTAMP_FILE=/home/nicolas/.restic_backup_timestamp # used to know when is the next backup planned
TEMP_LOG_FILE=/home/nicolas/.restic_temp_log # temporary log file that will be send to healthcheck.io
LOG_FILE=/home/nicolas/.restic_logs # local log file

# check if this script is already running
if [ -f "$PID_FILE" ]; then
  if ps -p $(cat $PID_FILE) > /dev/null; then
    echo $(date +"%Y-%m-%d %T") "File $PID_FILE exist. Probably backup is already in progress."
    exit 1
  else
    echo $(date +"%Y-%m-%d %T") "File $PID_FILE exist but process " $(cat $PID_FILE) " not found. Removing PID file."
    rm $PID_FILE
  fi
fi

# control if the time for backup has come
if [ -f "$TIMESTAMP_FILE" ]; then
  time_run=$(cat "$TIMESTAMP_FILE")
  current_time=$(date +"%s")

  if [ "$current_time" -lt "$time_run" ]; then
    echo "Too soon to backup"
    exit 2
  fi
fi

# check if the battery charge rate is at least 40% or if the battery is charging
if [[ $(upower -i $(upower -e | grep BAT) | grep --color=never -E "percentage" | cut -d":" -f2  | xargs | sed 's/%//') -lt 40  && $(upower -i $(upower -e | grep BAT) | grep --color=never -E "state" | cut -d":" -f2 | xargs) != "charging" ]]; then
  echo $(date +"%Y-%m-%d %T") "Battery too low, backup skipped."
  exit 4
fi

echo $$ > $PID_FILE
echo $(date +"%Y-%m-%d %T") "Backup start"

curl --retry 3 -X POST https://hc-ping.com/$(secret-tool lookup restic restic-backup-healthcheck-uuid)/start

ERRORS=0

# Backup Document folder
/usr/bin/restic backup /home/nicolas/Documents --exclude-file=/home/nicolas/.restic-exclude --exclude-caches >> $TEMP_LOG_FILE 2>&1

if [[ $? -ne 0 ]]; then 
  ERRORS=1
fi

# Backup Pictures folder
/usr/bin/restic backup /home/nicolas/Pictures --exclude-file=/home/nicolas/.restic-exclude --exclude-caches >> $TEMP_LOG_FILE 2>&1

if [[ $? -ne 0 ]]; then 
  ERRORS=1
fi

# Prune old backups
/usr/bin/restic forget --keep-daily 7 --keep-weekly 5 --keep-monthly 12 --keep-yearly 75 --prune >> $TEMP_LOG_FILE 2>&1

if [[ $? -ne 0 ]]; then 
  ERRORS=1
fi

cat "$TEMP_LOG_FILE" >> $LOG_FILE

cat $TEMP_LOG_FILE | curl --retry 3 -X POST --data-binary "@-" https://hc-ping.com/$(secret-tool lookup restic restic-backup-healthcheck-uuid)/$ERRORS

echo $(date +"%Y-%m-%d %T") "Backup finished"

# If there where errors retry backup sooner than in 8 hours
if [[ $ERRORS == 0 ]]; then
  echo $(date -d '+8 hour' +"%s") > $TIMESTAMP_FILE
fi

rm $PID_FILE
rm $TEMP_LOG_FILE

