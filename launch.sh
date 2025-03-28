#!/bin/sh

PAK_DIR="$(dirname "$0")"
PAK_NAME="$(basename "$PAK_DIR")"
PAK_NAME="${PAK_NAME%.*}"
[ -f "$USERDATA_PATH/$PAK_NAME/debug" ] && set -x

rm -f "$LOGS_PATH/$PAK_NAME.txt"
exec >>"$LOGS_PATH/$PAK_NAME.txt"
exec 2>&1

echo "$0" "$@"
cd "$PAK_DIR" || exit 1
mkdir -p "$USERDATA_PATH/$PAK_NAME"

architecture=arm
if uname -m | grep -q '64'; then
    architecture=arm64
fi

export HOME="$USERDATA_PATH/$PAK_NAME"
export LD_LIBRARY_PATH="$PAK_DIR/lib/$PLATFORM:$PAK_DIR/lib:$LD_LIBRARY_PATH"
export PATH="$PAK_DIR/bin/$architecture:$PAK_DIR/bin/$PLATFORM:$PAK_DIR/bin:$PATH"

SOURCE_FOLDERS="/Saves"
RCLONE_DESTINATION="/MinUI-Cloud-Backups"
RCLONE_BACKUP_PREFIX="Backup"
RCLONE_REMOTE_NAME="trimui"
RCLONE_CONFIG="$HOME/rclone.conf"

cleanup() (
    rm -f /tmp/stay_awake
    killall minui-presenter >/dev/null 2>&1 || true
)

show_message() (
    message="$1"
    seconds="$2"
    platform="$PLATFORM"

    if [ -z "$seconds" ]; then
        seconds="forever"
    fi

    killall minui-presenter >/dev/null 2>&1 || true
    echo "$message" 1>&2
    if [ "$platform" = "miyoomini" ]; then
        return 0
    fi
    if [ "$seconds" = "forever" ]; then
        minui-presenter --message "$message" --timeout -1 &
    else
        minui-presenter --message "$message" --timeout "$seconds"
    fi
)

show_confirm() (
    message="$1"

    killall minui-presenter >/dev/null 2>&1 || true
    echo "$message" 1>&2

    if ! minui-presenter --message "$message" \
        --confirm-show \
        --confirm-text "YES" \
        --cancel-show \
        --cancel-text "NO" \
        --action-show \
        --timeout 0; then
        return 1
    fi

    return 0
)

select_backup() (
    title="$1"
    backup_list="$(get_backup_list)"

    if [ -z "$backup_list" ]; then
        show_message "No backups found." 2
        return 1
    fi

    pretty_backup_list=$(prettify_backup_names "$backup_list")

    minui_list_file="/tmp/minui-list"
    rm -f "$minui_list_file"
    touch "$minui_list_file"

    echo "$pretty_backup_list" | while read -r backup; do
        echo "$backup" >> "$minui_list_file"
    done

    killall minui-presenter >/dev/null 2>&1 || true
    selected_backup=$(minui-list --file "$minui_list_file" --format text --title "$title")
    exit_code=$?
    if [ "$exit_code" -ne 0 ]; then
        return 1
    fi

    selected_backup=$(unprettify_backup_names "$selected_backup")
    echo "$selected_backup"
)

generate_recent_backup_name() (
    config="$RCLONE_CONFIG"
    remote_name="$RCLONE_REMOTE_NAME"
    dest_path="$RCLONE_DESTINATION"
    prefix="$RCLONE_BACKUP_PREFIX"

    recent_backup_file="/tmp/cloud-recent-backup"
    rm -f "$recent_backup_file"
    touch "$recent_backup_file"

    recent_backup=$(rclone --config "$config" --no-check-certificate ls "$remote_name:$dest_path" \
        | grep "$prefix-" \
        | sort -r \
        | head -n 1 \
        | awk '{print $2}')
    
    if [ -z "$recent_backup" ]; then
        echo "none" > "$recent_backup_file"
    else
        echo "$recent_backup" > "$recent_backup_file"
    fi
)

get_recent_backup_name() (
    recent_backup_file="/tmp/cloud-recent-backup"
    if [ ! -f "$recent_backup_file" ]; then
        generate_recent_backup_name
    fi

    cat "$recent_backup_file"
)

generate_backup_list() (
    config="$RCLONE_CONFIG"
    remote_name="$RCLONE_REMOTE_NAME"
    dest_path="$RCLONE_DESTINATION"
    prefix="$RCLONE_BACKUP_PREFIX"

    backup_list_file="/tmp/cloud-backup-list"
    rm -f "$backup_list_file"
    touch "$backup_list_file"

    rclone --config "$config" --no-check-certificate ls "$remote_name:$dest_path" \
        | grep "$prefix-" \
        | awk '{print $2}' \
        | sort -r > "$backup_list_file"
)

get_backup_list() (
    backup_list_file="/tmp/cloud-backup-list"
    if [ ! -f "$backup_list_file" ]; then
        generate_backup_list
    fi

    cat "$backup_list_file"
)

get_cloud_type() (
    config="$RCLONE_CONFIG"

    cloud_type="$(grep "^type" "$config" | awk '{print $3}')"
    if [ -z "$cloud_type" ]; then
        echo "unknown"
    else
        echo "$cloud_type"
    fi
)

prettify_backup_names() (
    backup_names="$1"
    prefix="$RCLONE_BACKUP_PREFIX"

    echo "$backup_names" | while read -r line; do
        line=$(echo "$line" | sed "s/$prefix-//g" | sed 's/.zip//g')
        line=$(echo "$line" | sed 's/-/\//g')
        echo "$line"
    done
)

unprettify_backup_names() (
    backup_names="$1"
    prefix="$RCLONE_BACKUP_PREFIX"

    echo "$backup_names" | while read -r line; do
        line=$(echo "$line" | sed 's/\//-/g')
        line="$prefix-$line.zip"
        echo "$line"
    done
)

create_backup() (
    config="$RCLONE_CONFIG"
    remote_name="$RCLONE_REMOTE_NAME"
    dest_path="$RCLONE_DESTINATION"
    source_folders="$SOURCE_FOLDERS"
    sd_path="$SDCARD_PATH"
    recent_backup="$(get_recent_backup_name)"
    prefix="$RCLONE_BACKUP_PREFIX"

    backup_dest_file="$prefix-$(date +%-Y-%m-%d).zip"

    if [ "$recent_backup" = "$backup_dest_file" ]; then
        if ! show_confirm "A backup for today already exists. Do you want to replace it?"; then
            return 1
        fi
    fi

    show_message "Creating backup..." forever
    temp_backup_path="/tmp/backup-$(date +%s).zip"
    echo "$source_folders" | while IFS= read -r path; do
        relative_path="${path#/}"
        if [ ! -d "$sd_path/$relative_path" ]; then
            show_message "Folder '$relative_path' was not found, skipping." 2
            continue
        fi 
        (cd "$sd_path" && 7zz a "$temp_backup_path" "$relative_path") || return 1
    done
    rclone \
        --config "$config" \
        --no-check-certificate \
        copyto \
        "$temp_backup_path" \
        "$remote_name:$dest_path/$backup_dest_file"
    rm -f "$temp_backup_path"

    show_message "Backup created successfully." 4
    return 0
)

restore_backup() (
    config="$RCLONE_CONFIG"
    remote_name="$RCLONE_REMOTE_NAME"
    dest_path="$RCLONE_DESTINATION"
    source_folders="$SOURCE_FOLDERS"
    sd_path="$SDCARD_PATH"

    selected_backup=$(select_backup "Select a backup to restore.")
    if [ -z "$selected_backup" ]; then
        return 1
    fi
    selected_backup_pretty=$(prettify_backup_names "$selected_backup")
    if ! show_confirm "Restoring $selected_backup_pretty will overwrite existing files if present. Do you want to continue?"; then
        return 1
    fi

    show_message "Restoring backup..." forever
    temp_backup_path="/tmp/backup-$(date +%s).zip"
    rclone \
        --config "$config" \
        --no-check-certificate \
        copyto \
        "$remote_name:$dest_path/$selected_backup" \
        "$temp_backup_path" \
        || return 1
    echo "$source_folders" | while IFS= read -r path; do
        relative_path="${path#/}"
        7zz l "$temp_backup_path" "$relative_path/*" >/dev/null 2>&1 || continue
        if [ -f "$sd_path/$relative_path" ]; then
            show_message "Folder '$relative_path' is a file, skipping." 2
            continue
        elif [ ! -d "$sd_path/$relative_path" ]; then
            mkdir -p "$sd_path/$relative_path"
        else
            if ! show_confirm "Replace files in '$relative_path' with those from the backup?"; then
                continue
            fi
        fi
        (cd "$sd_path" && 7zz x -aoa "$temp_backup_path" "$relative_path/*" -o.)
    done
    rm -f "$temp_backup_path"

    show_message "Backup restored successfully." 4
    return 0
)

delete_backup() (
    config="$RCLONE_CONFIG"
    remote_name="$RCLONE_REMOTE_NAME"
    dest_path="$RCLONE_DESTINATION"

    selected_backup=$(select_backup "Select a backup to delete.")
    if [ -z "$selected_backup" ]; then
        return 1
    fi
    selected_backup_pretty=$(prettify_backup_names "$selected_backup")
    if ! show_confirm "Are you sure you want to delete backup $selected_backup_pretty?"; then
        return 1
    fi

    show_message "Deleting backup..." forever
    rclone --config "$config" --no-check-certificate delete "$remote_name:$dest_path/$selected_backup"

    show_message "Backup deleted successfully." 4
    return 0
)

main_screen() (
    recent_backup="$(get_recent_backup_name)"

    minui_list_file="/tmp/minui-list.json"
    rm -f "$minui_list_file"
    touch "$minui_list_file"

    jq -n \
        '{
            items: [
                { "name": "Create a backup" }
            ]
        }' > "$minui_list_file"

    if [ "$recent_backup" != "none" ]; then
        jq \
            '.items += [
                { "name": "Restore a backup" },
                { "name": "Delete a backup" }
            ]' "$minui_list_file" > "${minui_list_file}.tmp" && mv "${minui_list_file}.tmp" "$minui_list_file"
    fi

    jq \
        --arg cloud_type "Cloud type: $(get_cloud_type)" \
        --arg most_recent_backup "Last backup date: $(prettify_backup_names "$recent_backup")" \
        '.items += [
            { "name": "Information", "features": { "is_header": true } },
            { "name": $most_recent_backup, "features": { "unselectable": true } },
            { "name": $cloud_type, "features": { "unselectable": true } }
        ]' "$minui_list_file" > "${minui_list_file}.tmp" && mv "${minui_list_file}.tmp" "$minui_list_file"

    killall minui-presenter >/dev/null 2>&1 || true
    minui-list --file "$minui_list_file" --format json --title "Cloud Backups" --item-key "items"
)

load() (
    show_message "Loading..." forever
    generate_recent_backup_name
    generate_backup_list
)

check_rclone_config() (
    config="$RCLONE_CONFIG"
    sd_path="$SDCARD_PATH"

    if [ -f "$sd_path/rclone.conf" ]; then
        mv -f "$sd_path/rclone.conf" "$config"
    fi

    if [ ! -f "$config" ]; then
        show_message "Rclone config not found." 2
        return 1
    fi
)

load_settings() {
    config_file="$PAK_DIR/config.json"
    if [ ! -f "$config_file" ]; then
        show_message "Config file not found: $config_file" 2
        return 1
    fi

    if jq -e '.settings.source_folders' "$config_file" >/dev/null 2>&1; then
        SOURCE_FOLDERS=$(jq -r '.settings.source_folders[]' "$config_file")
    fi

    if jq -e '.settings.rclone_destination' "$config_file" >/dev/null 2>&1; then
        RCLONE_DESTINATION=$(jq -r '.settings.rclone_destination' "$config_file")
    fi

    if jq -e '.settings.rclone_backup_prefix' "$config_file" >/dev/null 2>&1; then
        RCLONE_BACKUP_PREFIX=$(jq -r '.settings.rclone_backup_prefix' "$config_file")
    fi

    if jq -e '.settings.rclone_remote_name' "$config_file" >/dev/null 2>&1; then
        RCLONE_REMOTE_NAME=$(jq -r '.settings.rclone_remote_name' "$config_file")
    fi

}

main() {
    echo "1" >/tmp/stay_awake
    trap "cleanup" EXIT INT TERM HUP QUIT

    if [ "$PLATFORM" = "tg3040" ] && [ -z "$DEVICE" ]; then
        export DEVICE="brick"
        export PLATFORM="tg5040"
    fi

    if [ "$PLATFORM" = "miyoomini" ] && [ -z "$DEVICE" ]; then
        export DEVICE="miyoomini"
        if [ -f /customer/app/axp_test ]; then
            export DEVICE="miyoominiplus"
        fi
    fi

    if ! command -v minui-list >/dev/null 2>&1; then
        show_message "Minui-list not found." 2
        return 1
    fi

    if ! command -v minui-presenter >/dev/null 2>&1; then
        show_message "Minui-presenter not found." 2
        return 1
    fi

    if ! command -v 7zz >/dev/null 2>&1; then
        show_message "7zz not found." 2
        return 1
    fi

    if ! command -v rclone >/dev/null 2>&1; then
        show_message "Rclone not found." 2
        return 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        show_message "Jq not found." 2
        return 1
    fi

    allowed_platforms="tg5040"
    if ! echo "$allowed_platforms" | grep -q "$PLATFORM"; then
        show_message "$PLATFORM is not a supported platform." 2
    fi

    chmod +x "$PAK_DIR/bin/$PLATFORM/minui-list"
    chmod +x "$PAK_DIR/bin/$PLATFORM/minui-presenter"
    chmod +x "$PAK_DIR/bin/$architecture/rclone"
    chmod +x "$PAK_DIR/bin/$architecture/jq"
    chmod +x "$PAK_DIR/bin/$architecture/7zz"

    if ! load_settings; then
        return 1
    fi

    if ! check_rclone_config; then
        return 1
    fi

    if ! ping -c 1 -W 5 google.com >/dev/null 2>&1; then
        show_message "No internet connection." 2
        return 1
    fi

    load
    while true; do
        selection="$(main_screen)"
        exit_code=$?
        # exit codes: 2 = back button, 3 = menu button
        if [ "$exit_code" -ne 0 ]; then
            break
        fi

        if echo "$selection" | grep -q "^Create a backup$"; then
            if create_backup; then
                load
            fi
            continue
        elif echo "$selection" | grep -q "^Restore a backup$"; then
            if restore_backup; then
                load
            fi
            continue
        elif echo "$selection" | grep -q "^Delete a backup$"; then
            if delete_backup; then
                load
            fi
            continue
        fi

    done
}

main "$@"
