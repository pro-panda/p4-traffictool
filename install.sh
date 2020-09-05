#!/bin/bash

target_file="$HOME/.bashrc"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" 
echo -e "\n# Changes done by p4-traffictool" >> $target_file
echo "alias p4-traffictool=$DIR/p4-traffictool.sh" >> "$target_file"
echo "# End of changes by p4-traffictool" >> "$target_file"
echo "Added alias for p4-traffictool to $target_file"

source "$HOME/.bashrc"