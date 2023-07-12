#!/bin/bash

# Declare variables
declare -a EXTENSIONS=()
declare -a FILTERS=("%u" "%p")
declare -A FILTER_MAP=(
    ["owner"]="%u"
    ["permissions"]="%M"
    ["size"]="%s"
    ["modified"]="%Tb %Td %TH:%TM"
)
DIRECTORY=""

# Define the function for parsing command-line arguments
parse_arguments() {
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
            -f)
                shift
                while (( "$#" )) && [[ $1 != -* ]]; do
                    FILTERS=("${FILTER_MAP[$1]}" "${FILTERS[@]}")
                    shift
                done
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

search() {
    # 1. Declare two associative arrays.
    declare -A Files Size

    declare -a find_expr=()
    for ext in "${EXTENSIONS[@]}"; do
        find_expr+=(-o -name "*.$ext")
    done
    find_expr=("${find_expr[@]:1}")  # Skip the first "-o"

    printf_format=$(IFS=$'\t'; echo "${FILTERS[*]}")

    # 2. Use find with -printf.
    result=$(find "$DIRECTORY" -type f \( "${find_expr[@]}" \) -printf "$printf_format\n")
    while read -a line; do
        size=${line[-3]}
        owner=${line[-2]}

        Files["$owner"]+="${line[@]}"$'\n'
        ((Size["$owner"] += size))
    done <<< "$result"

    # 4. Sort owners by total file size.
    sorted_output=$(for owner in "${!Size[@]}"; do
        echo "${Size[$owner]} $owner"
    done | sort -nr)

    # # 5. Print each owner's total size and files.
    while read -r size owner; do
        # sorted_owners+=("$owner")
        printf "Owner: %s, Total Size: %s\n" "$owner" "${size}"
        printf "%s\n" "${Files[$owner]}"
    done <<< "$sorted_output"
}

# Define main function
main() {
    parse_arguments "$@"
    # Further processing...
    search
}

# Call the main function
main "$@"
