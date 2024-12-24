#!/bin/bash
# installer for cargo-distributed programs

echo "Performing full cargo upgrade..."
cargo install cargo-update
cargo install-update -a

echo "Installing git-credential KeepassXC helper"
cargo install --locked --features notification git-credential-keepassxc
cargo install-update-config git-credential-keepassxc --enforce-lock --feature notification
$HOME/.cargo/bin/git-credential-keepassxc configure
git config --global --replace-all credential.helper 'keepassxc --git-groups'

echo "Installing SSGen"
cargo install ssgen

echo "Installing Sway utilities from local repo"
for NAME in \
    "../src/sway-bar-status/install.sh" \
    "../src/sway-window-title-as-workspace/install.sh"
do
    chmod +x "$NAME"
    "$NAME"
done
