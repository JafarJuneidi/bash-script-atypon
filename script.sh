#!/bin/bash

# Declare variables
declare -a EXTENSIONS=()
DIRECTORY=""
SIZE=""
PERMISSIONS=""
MODIFIED=""

# Define the function for parsing command-line arguments
parse_arguments() {
    if [[ $1 == "--help" ]]; then
        display_help
        exit 0
    fi

    DIRECTORY=$1
    shift
    while (( "$#" )); do
        case "$1" in
            -e)
                shift
                while (( "$#" )) && [[ $1 != -* ]]; do
                    EXTENSIONS+=("$1")
                    shift
                done
                ;;
            -s)
                shift
                if [[ "$1" =~ ^[+-]?[0-9]+[cwkMG]?$ ]]; then
                    SIZE="$1"
                    shift
                else
                    echo "Invalid size: $1. Size should be in the format [+-]num[unit]."
                    exit 1
                fi
                ;;
            -perm)
                shift
                if [[ "$1" =~ ^-?[0-7]{3,4}$ || "$1" =~ ^/[ugo]*[+-=][rwx]*$ || "$1" =~ ^-/[ugo]*[+-=][rwx]*$ ]]; then
                    PERMISSIONS="$1"
                    shift
                else
                    echo "Invalid permissions: $1. Permissions should be in octal format (000-777) or symbolic format (ugoa...)."
                    exit 1
                fi
                ;;
            -mtime)
                shift
                if [[ "$1" =~ ^[+-]?[0-9]+$ || "$1" =~ ^[0-9]+[smhdw]?$ ]]; then
                    MODIFIED="$1"
                    shift
                else
                    echo "Invalid modified time: $1. Modified time should be a number (days), optionally preceded by '+' or '-', or optionally followed by 's' (seconds), 'm' (minutes), 'h' (hours), 'd' (days), or 'w' (weeks)."
                    exit 1
                fi
                ;;
            *)
                echo "Unknown option: $1"
                display_help
                exit 1
                ;;
        esac
    done
}

display_help() {
    echo "Usage: $0 <directory> [OPTIONS]"
    echo
    echo "Search files in <directory> based on specified criteria."
    echo
    echo "Available options:"
    echo "  -e <extension>     Search for files with the specified extension."
    echo "                     This option can be used multiple times to search for files with different extensions."
    echo "  -s <size>          Search for files with a specific size. Size should be in the format [+-]num[unit]."
    echo "                     '+' means 'more than', '-' means 'less than'. Unit can be 'c' (bytes), 'w' (two-byte words),"
    echo "                     'k' (kilobytes), 'M' (megabytes), 'G' (gigabytes)."
    echo "  -perm <mode>       Search for files with specific permissions. <mode> can be either an octal number (000-777)"
    echo "                     or a symbolic mode starting with a slash (/[ugo]*[+-=][rwx]*)."
    echo "  -mtime <n>         Search for files modified n*24 hours ago."
    echo "                     '<n' means 'less than n', '>n' means 'more than n', and 'n' means exactly n."
    echo "                     '<n' is equivalent to '-n', and '>n' is equivalent to '+n'."
    echo "                     'n' can also optionally be followed by 's' (seconds), 'm' (minutes), 'h' (hours),"
    echo "                     'd' (days), or 'w' (weeks)."
    echo "  --help             Display this help message and exit."
    echo
    echo "Example:"
    echo "  $0 /var/log -e log -e txt -s +10k -perm 644 -mtime -7"
}

search() {
    declare -A Files Size

    declare -a find_extensions_expr=()
    for ext in "${EXTENSIONS[@]}"; do
        find_extensions_expr+=(-o -name "*.$ext")
    done
    find_extensions_expr=("${find_extensions_expr[@]:1}")  # Skip the first "-o"

    declare -a find_filters_expr=()
    [[ -n $SIZE ]] && find_filters_expr+=(-size $SIZE)
    [[ -n $PERMISSIONS ]] && find_filters_expr+=(-perm $PERMISSIONS)
    [[ -n $MODIFIED ]] && find_filters_expr+=(-mtime $MODIFIED)

    printf_format="%M\t%s\t%u\t%Tb %Td %TH:%TM\t%p\n"

    result=$(find "$DIRECTORY" -type f \( "${find_extensions_expr[@]}" \) "${find_filters_expr[@]}" -printf "$printf_format")
    while read -a line; do
        size=${line[1]}
        owner=${line[2]}

        Files["$owner"]+="${line[@]}"$'\n'
        ((Size["$owner"] += size))
    done <<< "$result"

    sorted_output=$(for owner in "${!Size[@]}"; do
        echo "${Size[$owner]} $owner"
    done | sort -nr)

    declare total_size=0
    declare total_files=0

    {
        while read -r size owner; do
            printf "Owner: %s, Total Size: %s\n" "$owner" "$size"
            printf "%s\n" "${Files[$owner]}"

            ((total_size += size))
            ((total_files += $(echo -n "${Files[$owner]}" | grep -c '^')))
        done <<< "$sorted_output"

        printf "Total size of all files: %s\n" "$total_size"
        printf "Total number of files: %s\n" "$total_files"
    } > file_analysis.txt

    echo "File report generated to file_analysis.txt"
}

main() {
    parse_arguments "$@"
    search
}

main "$@"
