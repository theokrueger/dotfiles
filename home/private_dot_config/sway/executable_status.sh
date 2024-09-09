#!/bin/bash
# status message for swaybar

IS_LAPTOP=$(
    case $HOSTNAME in
        'thonkpad')
            true
            ;;
        'linsuslap')
            true
            ;;
        *)
            false
            ;;
    esac
    )

sep='|'
add_sep() {
    if [[ "$1" != "" ]]; then
        printf "%s" " $1 $sep"
    fi
}

# current time. ex: 1970-01-01 00:00:00
cur_time=''
update_time() {
    cur_time=$(date '+%F %H:%M:%S')
}

# battery charge. ex: =50%
cur_battery=''
update_battery() {
    if [[ $IS_LAPTOP ]]; then return; fi
    battery_cap=$(cat /sys/class/power_supply/BAT*/capacity)
    battery_status=$(
        case $(cat /sys/class/power_supply/BAT*/status) in
            'Charging')
                printf "%s" '^'
                ;;
            'Discharging')
                if [[ $battery_cap -le 15 ]]; then
                    # will hang on swaynag, intentional design
                    swaynag -m "battery is LOW!!!!!"
                fi
                printf "%s" 'v'
                ;;
            *)
                printf "%s" '='
                ;;
        esac
                  )
    cur_battery="$battery_status$battery_cap%"
}

# backlight brightness. ex: *63%
cur_brightness=""
backlight_max=0
backlight_level_file=""
case $HOSTNAME in
    'thonkpad')
        backlight_max=$(cat /sys/class/backlight/acpi_video0/max_brightness)
        backlight_level_file="/sys/class/backlight/acpi_video0/brightness"
        ;;
    'linsuslap')
        backlight_max=$(cat /sys/class/backlight/intel_backlight/max_brightness)
        backlight_level_file="/sys/class/backlight/intel_backlight/brightness"
        ;;
    *)
        ;;
esac

update_brightness() {
    if [[ $IS_LAPTOP ]]; then return; fi
    level=$(cat "$backlight_level_file")
    if [[ $level == $backlight_max ]]; then
        cur_brightness='*MAX'
    else
        cur_brightness=$(printf "*%02i%%" "$((level * 100 / backlight_max))")
    fi
}

# memory usage. ex: 1.2Gi
cur_memory=''
update_memory() {
    cur_memory=$(printf "#%s" "$(free -h | awk 'FNR == 2 {print $3}')")
}

# storage usage. ex: sda 42%
STORAGE_DRIVES=$(df -h | awk '{print $1}' | grep /dev/) # list all drives that are under /dev/
STORAGE_LENGTH=$(printf "%s\n" "$STORAGE_DRIVES" | sed 's/.*\///' | awk '{print length, $0}' | sort -nr | head -n 1 | awk '{print $1;}') # get length of the longest drive name
STORAGE_NUM=$(printf "%s\n" $STORAGE_DRIVES | wc -w) # count number of drives in list
STORAGE_DRIVES=( $STORAGE_DRIVES ) # convert list of drives into array

cur_storage_use=''
update_storage_use() {
    drive=${STORAGE_DRIVES[ $((clock / 10 % STORAGE_NUM)) ]}
    drive_short=$(printf "%s" "$drive" | sed 's/.*\///')

    cur_storage_use=$(
        printf "%*s %02d%%" \
               $STORAGE_LENGTH \
               "$drive_short" \
               "$(df -h $drive | tail -1 | awk '{print $5}'b | sed 's/.$//')"
                   )
}

# now playingb. ex: Touhiron 3:04/4:35 [69%]
cur_track=''
update_track() {
    buf=$(mpc 2> /dev/null)
    status=$(printf "%s" "$buf" | awk 'FNR == 2 {print $1}')
    if [[ "$status" == '[playing]' ]]; then
        cur_track="$(printf "%s" "$buf" | awk 'FNR == 1 {print}') \
         $(printf "%s" "$buf"| awk 'FNR == 2 {print $3}') \
         [$(printf "%s" "$buf" | awk 'FNR == 3 {print $2}')]"
    else
        cur_track=''
    fi
}

# combined
clock=0
print_status() {
    update_time
    update_track
    if [[ $((clock % 5)) == 0 ]]; then
        update_brightness
        if [[ $((clock % 10)) == 0 ]]; then
            update_battery
            update_memory
            update_storage_use
        fi
    fi
    printf "%s%s%s%s%s%s%s%s\n" \
        "$(add_sep "$cur_track")" \
        " $cur_storage_use" \
        " $sep" \
        " $cur_memory" \
        " $sep" \
        "$(add_sep "$cur_brightness")" \
        "$(add_sep "$cur_battery")" \
        " $cur_time"

    clock=$((clock + 1))
}

while true; do
    print_status
    sleep 1
done


