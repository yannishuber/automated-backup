#!/bin/bash

source /users/yannis/.restic-config

PID_FILE=~/.restic_backup.pid
TIMESTAMP_FILE=~/.restic_backup_timestamp

if [ -f "$PID_FILE" ]; then
  if ps -p $(cat $PID_FILE) > /dev/null; then
    echo $(date +"%Y-%m-%d %T") "File $PID_FILE exist. Probably backup is already in progress."
    exit 1
  else
    echo $(date +"%Y-%m-%d %T") "File $PID_FILE exist but process " $(cat $PID_FILE) " not found. Removing PID file."
    rm $PID_FILE
  fi
fi

if [ -f "$TIMESTAMP_FILE" ]; then
  time_run=$(cat "$TIMESTAMP_FILE")
  current_time=$(date +"%s")

  if [ "$current_time" -lt "$time_run" ]; then
    exit 2
  fi
fi

if [[ $(pmset -g ps | head -1) =~ "Battery" ]] && [[ $(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1) < 40 ]]; then
  echo $(date +"%Y-%m-%d %T") "Battery too low, backup skipped."
  exit 4
fi

echo $$ > $PID_FILE
echo $(date +"%Y-%m-%d %T") "Backup start"

# Backup Document folder
/opt/homebrew/bin/restic backup /users/yannis/documents --exclude-file=/users/yannis/.restic-exclude

# Prune old backups
/opt/homebrew/bin/restic forget --keep-daily 7 --keep-weekly 5 --keep-monthly 12 --keep-yearly 75 --prune

echo $(date +"%Y-%m-%d %T") "Backup finished"
echo $(date -v +8H +"%s") > $TIMESTAMP_FILE

rm $PID_FILE

