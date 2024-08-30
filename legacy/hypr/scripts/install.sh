#!/bin/bash
cd "$(dirname "$0")"
LEVEL=$1
indent() {
        SPACES=''
        for i in $(seq 0 $LEVEL); do
                SPACES="$SPACES  "
        done
        sed "s/^/$SPACES/"
}

dest="$HOME/.config/hypr/scripts"
mkdir -p $dest
declare -a files=(xdg-portal-hyprland.sh lock.sh lock.png)
declare -a dirs=()

for f in "${files[@]}"; do
#        echo "copying file $f to $dest" | indent
        cp --update=older --interactive --recursive --backup --suffix=".old" --reflink=auto --preserve=mode,ownership --verbose "$f" "$dest"  | indent
        test -f "$f" && test "$(echo $f | awk -F. '{print $NF}')" == "sh" && echo "setting permissions for $f" && chmod +x "$dest/$f"
done

for d in "${dirs[@]}"; do
        echo "recursing into directory: $d"  | indent
        (test -x "$d/install.sh" && "$d/install.sh" "$((LEVEL + 1))" || echo "ERROR: installer not found in $d!")  | indent
        echo "exiting $d" | indent
done
