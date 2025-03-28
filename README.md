# MinUI Cloud Backups

A [MinUI](https://github.com/shauninman/MinUI) and [NextUI](https://github.com/LoveRetro/NextUI) pak to to back up saves, screenshots and other folders to cloud storage providers like Google Drive and Dropbox.

## Description

MinUI Cloud Backups is a pak designed for MinUI and NextUI. Its aim is to simplify the process of backing up folders, such as game saves, game states or screenshots, to popular cloud storage providers like Google Drive, Dropbox, OneDrive and [more](https://rclone.org/overview). The pak automates the process of compressing the data into a .zip file and uploading it using [Rclone](https://rclone.org) directly from the MinUI device. Currently, the features include the ability to manage multiple backups by either creating, restoring or deleting them. The backups are stored in a configurable folder in the cloud and are named with a timestamp. They can be restored to the device at any time by selecting the backup from a list.

## Requirements

This pak is designed for the following MinUI Platforms and devices:

- `tg5040`: Trimui Brick (formerly `tg3040`), Trimui Smart Pro

The pak may work on other platforms and devices, but it has not been tested on them.

## Installation

### Install the pak

1. Mount your MinUI SD card.
2. Download the latest [release](https://github.com/ben16w/minui-cloud-backup/releases) from GitHub.
3. Copy the zip file to the correct platform folder in the "/Tools" directory on the SD card.
4. Extract the zip in place, then delete the zip file.
5. Confirm that there is a `/Tools/$PLATFORM/Cloud.Backup.pak/launch.sh` file on your SD card.

Note: The platform folder name is based on the name of your device. For example, if you are using a TrimUI Brick, the folder is "tg3040". Alternatively, if you're not sure which folder to use, you can copy the .pak folders to all the platform folders.

### Setup Rclone

This pak requires you to firstly set up `rclone` on your local machine and then copy the configuration to your MinUI device. It is only necessary to generate the configuration and authenticate `rclone` to access your storage. Once the process is completed, `rclone` is no longer needed on your local machine and can be safely removed. The steps cannot currently be completed on the MinUI device itself due to the fact it does not have a web browser.

Follow these steps to install and configure `rclone`:

1. Follow the [instructions](https://rclone.org/install/) to install `rclone` on your local machine.
2. Launch your terminal or command prompt.
3. Navigate to the directory where `rclone` is downloaded. Type `rclone config` and press Enter. This will start the configuration process.
4. Follow the prompts to create a new remote:
    - Type `n` to create a new remote and press Enter.
    - Enter the name `trimui` for the remote and press Enter.
    - Select your cloud storage provider from the list and press Enter.
    - Follow the prompts to authenticate and configure the remote. This may involve opening a web browser to authorize `rclone` with your cloud storage provider.
5. Once the remote is configured, you can verify it by running `rclone lsd trimui:`.
6. Locate the `rclone.conf` file on your local machine. This file contains the configuration settings for `rclone` and is typically located in `~/.config/rclone/rclone.conf` on Linux and macOS or `%USERPROFILE%\.config\rclone\rclone.conf` on Windows.
7. Copy the `rclone.conf` file to root of the MinUI SD card. It will be moved to the correct location by the pak.
8. Unmount your SD Card and insert it into your MinUI device.

For detailed instructions and troubleshooting, refer to the [rclone documentation](https://rclone.org/docs/).

## Usage

1. Navigate to the Tools menu on your MinUI device.
2. Select the "Cloud Backups" option.
3. Select `Create Backup` to start the backup process. This will create a zip file and upload it to the configured cloud storage.
4. Alternatively, you can select `Restore Backup` to restore a previously created backup. This will download the zip file from the cloud storage and extract it to the device.
5. You can also select `Delete Backup` to delete a backup file from the cloud storage.

## Settings

The `config.json` file in the Cloud Backups pak folder allows you to customize the behaviour of the pak.

### How to edit the `config.json` file

1. Mount your MinUI SD card on your computer.
2. Navigate to the `/Tools/$PLATFORM/Cloud.Backup.pak/` folder.
3. Open the `config.json` file in a text editor.
4. Modify the settings as needed, ensuring the JSON syntax remains valid.
5. Save the file and unmount your SD card.
6. Insert the SD card back into your MinUI device.

### Available settings

#### `source_folders`

Specifies the folders on your MinUI device that will be included in the backup. Add or remove folder paths in the array. For example, to include an additional folder, modify it as follows:

```json
"source_folders": [
    "/Saves",
    "/Screenshots",
    "/.userdata"
]
```

#### `rclone_destination`

Defines the destination folder on your cloud storage where backups will be stored. Replace the value with the desired folder path. For example:

```json
"rclone_destination": "/MyTrimuiBackups"
```

#### `rclone_backup_prefix`

Sets the prefix for the backup file names. This will be followed by a timestamp and the `.zip` extension. For example: `MyTrimuiBackup-2025-01-01.zip`. Update the prefix to your preferred name. For example:

```json
"rclone_backup_prefix": "MyTrimuiBackup"
```

#### `rclone_remote_name`

Specifies the name of the `rclone` remote configured for your cloud storage. Ensure this matches the name of the remote you configured in `rclone`. By default, the remote name is `trimui`. For example:

```json
"rclone_remote_name": "trimui"
```

## Acknowledgements

- [MinUI](https://github.com/shauninman/MinUI) by Shaun Inman
- [minui-list](https://github.com/josegonzalez/minui-list) and [minui-presenter](https://github.com/josegonzalez/minui-presenter) by Jose Diaz-Gonzalez
- Also, thank you, Jose Diaz-Gonzalez, for your pak repositories, which this project is based on.

## License

This project is released under the MIT License. For more information, see the [LICENSE](LICENSE) file.
