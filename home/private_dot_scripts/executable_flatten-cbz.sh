#!/bin/bash
# flattens a .cbz file

OUTDIR="out"
TEMPDIR="/tmp/flatten-cbz/"
TARGET_FILE="$1"

mkdir "$OUTDIR"
rm "$TEMPDIR" -r && mkdir "$TEMPDIR"

unzip "$TARGET_FILE" -d "$OUTDIR"

find "$TEMPDIR" -type f -exec bash -c 'file=${1#./}; mv "$file" "${file//\//_}"' _ '{}' \;

find "$TEMPDIR"/* -type d -exec rm -r "{}" \;

zip "$OUTDIR$TARGET_FILE" "$TEMPDIR"/*
