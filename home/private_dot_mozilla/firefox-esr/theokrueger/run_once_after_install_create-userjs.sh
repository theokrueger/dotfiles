#!/bin/bash
# run updater script and update userjs file
cd ~/.mozilla/firefox-esr/theokrueger/
./prefsCleaner.sh -s -d
./updater.sh -d -e
