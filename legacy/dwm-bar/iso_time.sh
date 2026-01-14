#!/bin/sh

# track module for dwm-bar
# theokrueger <git@gitlab.com/theokrueger>
# GNU GPLv3

# module dependencies:
# playerctl

# display currently playing track and its volume

time()
{
        # prints date in format:
        # [<weekday>] <fullyear>-<month>-<day> <time>
        # for example:
        # [4] 1970-01-01 00:00

        # IMPORTANT NOTE: i love iso-8601
        echo "$( date "+[%u] %F %R" )"
}
