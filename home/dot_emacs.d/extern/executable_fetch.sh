#!/bin/bash
# download & update external files not available thru MELPA/ELPA

# list all files
declare -A FILES=(
   # profile the .emasc file, run with
   # /usr/bin/emacs -Q -l ~/.emacs.d/extern/profile-dotemacs.el -f profile-dotemacs
    [profile-dotemacs.el]="https://web.archive.org/web/20190904064127if_/http://www.randomsample.de:80/profile-dotemacs.el"
   # c clang style for clang format
   [c-linux.clang-format]="https://raw.githubusercontent.com/torvalds/linux/refs/heads/master/.clang-format"
)
# patches to those files
declare -A PATCHES=(
    [profile-dotemacs.el]="patches/profile-dotemacs.el.patch"
    [c-linux.clang-format]="patches/c-linux.clang-format.patch"
)

echo -e "begin files update\n"

for key in "${!FILES[@]}"; do
    # backup
    if [[ -f "$key" ]]; then
	echo "BACKING UP old $key"
	cp "$key" "$key".old
    fi
    # download
    echo "DOWNLOADING $key"
    curl "${FILES[$key]}" -o "$key"
    head -n 2 "$key"
    echo "(...)"
    tail -n 2 "$key"
    echo "lines: $(wc -l "$key")"
    echo ""
done

echo "end files update"

echo -e "begin files modification\n"

for key in "${!PATCHES[@]}"; do
    patch="${PATCHES[$key]}"
    # backup
    if [[ -f "$key" ]]; then
	echo "BACKING UP $key"
	cp "$key" "$key".orig
    fi
    # apply patch
    echo "APPLYING PATCH $patch to $key"
    patch "$key" < "$patch" || read -r
    echo "DONE"
    echo ""
done

echo "end files modification"
