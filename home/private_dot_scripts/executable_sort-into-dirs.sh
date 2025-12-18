#!/bin/bash
# https://stackoverflow.com/questions/10694246/bash-move-files-based-on-first-letter-of-name
dirs=(a b c d e f g h i j k l m n o p q r s t u v w x y z)
shopt -s nocasematch

for file in *
do
    for dir in "${dirs[@]}"; do

        if [ -d "$file" ]; then
            echo 'this is a dir, skipping'
            break
        else
            if [[ $file =~ ^[$dir] ]]; then
                echo "----> $file moves into -> $dir <----"
                mkdir -p "$dir"
                mv "$file" "$dir/"
                break
            fi
        fi
    done
done
