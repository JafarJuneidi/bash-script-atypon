#!/bin/bash

# Function to display help information
function display_help {
    echo "Usage: $0 [OPTIONS] DIRECTORY"
    echo
    echo "Search for files in a directory and generate a file analysis report."
    echo
    echo "Options:"
    echo "  -e, --extensions EXTENSIONS   Comma-separated list of file extensions to search for"
    echo "  -f, --filter FILTER          Comma-separated list of file attributes to include in the report"
    echo "  -h, --help                   Display this help and exit"
    echo
    echo "DIRECTORY must be a valid directory path. If not provided, the current directory is used."
}

# Function to handle errors
function handle_error {
    echo "Error: $1" >&2
    echo "Try '$0 --help' for more information." >&2
    exit 1
}

# Parse command-line arguments
while (( "$#" )); do
    case "$1" in
        -e|--extensions)
            if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                EXTENSIONS=$2
                shift 2
            else
                handle_error "Option requires an argument -- '$1'"
            fi
            ;;
        -f|--filter)
            if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                FILTER=$2
                shift 2
            else
                handle_error "Option requires an argument -- '$1'"
            fi
            ;;
        -h|--help)
            display_help
            exit 0
            ;;
        --) # end argument parsing
            shift
            break
            ;;
        -*|--*=) # unsupported flags
            handle_error "Unsupported flag '$1'"
            ;;
        *) # preserve positional arguments
            DIRECTORY=$1
            shift
            ;;
    esac
done

# Validate inputs
if [ -z "$DIRECTORY" ]; then
    DIRECTORY="."
elif [ ! -d "$DIRECTORY" ]; then
    handle_error "Invalid directory '$DIRECTORY'"
fi
if [ -z "$EXTENSIONS" ]; then
    EXTENSIONS="txt"
fi

# Define a mapping from attribute names to -printf format specifiers
declare -A FORMAT_MAP=( ["permissions"]="%M" ["size"]="%s" ["timestamp"]="%Tb %Td %TH:%TM" )

# Build the format string for -printf from the filter
IFS=","
FORMAT_STRING="" # Start with empty string
for ATTRIBUTE in $FILTER; do
    FORMAT_SPECIFIER=${FORMAT_MAP[$ATTRIBUTE]}
    if [ -z "$FORMAT_SPECIFIER" ]; then
        handle_error "Invalid attribute '$ATTRIBUTE'"
    fi
    FORMAT_STRING+="$FORMAT_SPECIFIER\t"
done
FORMAT_STRING+="%u\t%p\n" # Append owner and filename

# Generate file analysis report
{
    for EXTENSION in $EXTENSIONS; do
        find "$DIRECTORY" -name "*.$EXTENSION" -printf "$FORMAT_STRING"
    done | sort -k3nr | column -t
} > file_analysis.txt

