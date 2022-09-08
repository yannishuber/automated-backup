# Automated Encrypted Backup Using Restic

Small script which automates my backups using [restic](https://restic.net/) and stores them encrypted on [Infomaniak Swiss Backup](https://www.infomaniak.com/en/swiss-backup).

## Installation Ubuntu

To automate backups follow these simple steps:

  1. **Save connection details in the `secret-tool` secret manager**

     The connection details for the Infomaniak OpenStack Swift Keystone 3 backup location can be found in the Infomaniak Manager under `Swiss Backup > Device management`.

     First install ```secret-tool```

     ```bash
     apt-get install libsecret-tools
     ```

     There are 4 secrets we want to add to the secret-tool keychain:

     ```bash
     # Infomaniak Swiss Backup username
     secret-tool store --label "restic" restic restic-os-username
     # Infomaniak Swiss Backup password
     secret-tool store --label "restic" restic restic-os-password
     # Restic password used to encrypt the backups
     secret-tool store --label "restic" restic restic-password
     # Healthcheck UUID
     secret-tool store --label "restic" restic restic-backup-healthcheck-uuid
     ```

     The ```restic-password``` keychain entry does not come from the OpenStack backup configuration. It is the encryption key used by restic to encrypt the backup before sending it to the remote location.

     The ```restic-backup-healthcheck-uuid``` keychain entry does come from [healthchecks.io](https://healthchecks.io)

  2. **Configuration file**

    Create the file ```/home/user/.restic-config``` with this content:
    ```bash
    export DISPLAY=:0 # see https://askubuntu.com/questions/1191300/how-to-use-secret-tool-in-cronjob-with-non-root-user
    export OS_AUTH_URL=https://swiss-backup02.infomaniak.com/identity/v3
    export OS_USER_DOMAIN_NAME=default
    export OS_PASSWORD=$(secret-tool lookup restic restic-os-password)
    export OS_USERNAME=$(secret-tool lookup restic restic-os-username)
    export OS_PROJECT_DOMAIN_NAME=default
    export OS_PROJECT_NAME="sb_project_$(secret-tool lookup restic restic-os-username)"
    export RESTIC_PASSWORD=$(secret-tool lookup restic restic-password)
    export RESTIC_REPOSITORY=swift:infomaniak:/
    ```

  3. **Copy the backup script.**

     Copy the file `restic-backup.sh` to `~/Scripts/` and execute
     ```bash
     chmod +x ~s/scripts/restic-backup-linux.sh
     ```

  4. **Automate the backup using ```cron```**

    Add the following line to your ```/etc/crontab```

    ```bash
    */10 * * * * user /home/user/scripts/restic-backup.sh >> /home/user/scripts/restic-backup-cron.log 2>&1
    ```



## Installation MacOS

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
Nicolas Feyer, <https://github.com/nicolasfeyer>
