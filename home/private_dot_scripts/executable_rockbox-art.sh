#!/bin/bash
# short script to strip cover art from files and resize art for rockbox

if [[ "$(which kid3-cli)" == "" ]] || [[ "$(which magick)" == "" ]]; then
    echo "Please install imagemagick and kid3"
    return
fi

strip_art() {
    echo "removing embedded art: $1"
    kid3-cli -c 'set Picture ""' "$1"
}

convert_art() {
    FOLDER="$(dirname "$1")"
    TARGET="$FOLDER/cover.jpg"
    echo "resizing folder art: $1 -> $TARGET"
    convert -resize 500x500 "$1" "$TARGET"
    echo "converting to non-progressive jpeg"
    jpegtran "$TARGET" > /tmp/temp_jpeg_nonprog
    mv /tmp/temp_jpeg_nonprog "$TARGET"
}


if [ "$1" = "" ]; then
    echo "please supply a path!"
    echo "usage - rockbox-art.sh <path>"
    exit
fi

echo "converting folder art..."
find "$1" -type f | grep "cover\." | while read f; do convert_art "$f"; done
echo -e "done!\n"

echo "stripping embedded art..."
#find "$1" -type f | grep "\(\.flac\|\.mp3\|\.m4a\|\.ogg\)" | while read f; do strip_art "$f"; done
echo "done!"
