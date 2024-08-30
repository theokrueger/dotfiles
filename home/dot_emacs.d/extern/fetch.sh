#!/bin/sh
# download & update external .el files not available thrue MELPA/ELPA

# list all files
declare -A FILES=(
   # /usr/bin/emacs -Q -l ~/.emacs.d/extern/profile-dotemacs.el -f profile-dotemacs
    [profile-dotemacs.el]="https://web.archive.org/web/20190904064127if_/http://www.randomsample.de:80/profile-dotemacs.el"
)

echo -e "begin files update\n"

for key in "${!FILES[@]}"; do
    out="./$key"
    # backup
    if [[ -f $out ]]; then
	echo "BACKING UP $key"
	mkdir -p "./backup"
	cp $out "./backup/"
    fi
    # download
    echo "DOWNLOADING $key"
    curl "${FILES[$key]}" -o $out
    head -n 1 $out
    echo "(...)"
    tail -n 1 $out
    echo ""
done

echo "end files update"
