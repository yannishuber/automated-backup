# Automated Encrypted Backup Using Restic

Small script which automates my backups using [restic](https://restic.net/) and stores them encrypted on [Infomaniak Swiss Backup](https://www.infomaniak.com/en/swiss-backup).

## Installation

To automate backups follow these simple steps:

  1. **Save connection details in the macOS keychain.**
     
     The connection details for the Infomaniak OpenStack Swift Keystone 3 backup location can be found in the Infomaniak Manager under `Swiss Backup > Device management`.

     There are 4 secrets we want to add to the macOS keychain:

     ```bash
     security add-generic-password -s restic-backup-os-password -a restic-backup -w

     security add-generic-password -s restic-backup-os-username -a restic-backup -w

     security add-generic-password -s restic-backup-os-project-name -a restic-backup -w

     security add-generic-password -s restic-backup-repository-password -a restic-backup -w
     ```

     The last keychain entry does not come from the OpenStack backup configuration. It is the encryption key used by restic to encrypt the backup before sending it to the remote location.
  2. **Configure restic.**
     
     The configuration files for restic can be found in my dotfiles repository.

  3. **Copy the backup script.**
     
     Copy the file `restic-backup.sh` to `~/Scripts/` and execute 
     ```bash
     chmod +x ~/Scripts/restic-backup.sh 
     ```

  3. **Automating the backup using `launchd`.**
     
     Copy the file `ch.yannishuber.restic-backup.plist` to `~/Library/LaunchAgents/` and execute 
     ```bash
     launchctl bootstrap gui/501 ~/Library/LaunchAgents/ch.yannishuber.restic-backup.plistq
     ```
  4. **Give `bash` full disk access.**

     In order for the script to execute properly, we have to give `/bin/bash` full disk access in the macOS system preferences: `System Preferences > Security & Privacy > Full Disk Access`.

That's it. The backups will be executed automatically every 8 hours.

## Credits

Szymon Krajewski, <https://szymonkrajewski.pl/macos-backup-restic/>