#!/bin/bash
# installer for pip packages

# required by https://github.com/cyrus-and/gdb-dashboard (~/.gdbinit)
echo "Installing python dependencies for ~/.gdbinit"
pip install --user pygments
