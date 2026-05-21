#!/bin/bash
# show memory usage of a given PID

if [[ "$1" == "" ]]; then
  echo "usage: mem-usage.sh <PID>"
  exit
fi

pid="$1"
page_size=$(getconf PAGE_SIZE)
rss_pages=$(cat /proc/$pid/statm | awk '{print $2}')
rss_kb=$((rss_pages * page_size / 1024))
echo "Process $pid is using $rss_kb KB of memory."
