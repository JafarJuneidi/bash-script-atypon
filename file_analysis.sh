#!/bin/bash

show_help() {
    cat << EOF
-------------------------------------------------------------------------------
Usage: ./file_analysis.sh [DIRECTORY] [EXTENSION]"

Search for all files with a specific extension in the given directory and its subdirectories."
Generate a comprehensive report that includes file details such as size, owner, permissions, and last modified timestamp."
Group the files by owner and sort the file groups by the total size occupied by each owner."
Save the report in a file named \"file_analysis.txt\"."

Options:
  DIRECTORY    specify the directory path to search
  EXTENSION    specify the file extension to search for
-------------------------------------------------------------------------------
EOF
}

validate_input() {
    if [[ -z "$1" || -z "$2" ]]; then
        echo "Error: both DIRECTORY and EXTENSION arguments are required."
        show_help
        exit 1
    fi

    if [ ! -d "$1" ]; then
        echo "Error: $1 is not a valid directory."
        exit 1
    fi
}

main() {
    validate_input $1 $2

    echo "Generating file analysis report..."

    echo "Permissions\tOwner\tSize\tLast modified\tname\n" > file_analysis.txt
    find "$1" -name "*.$2" -printf "%M\t%u\t%s\t%Tb %Td %TH:%TM\t%p\n" | sort -k3rn >> file_analysis.txt

    echo "File analysis report saved as file_analysis.txt."
}

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
else
    main $@
fi

