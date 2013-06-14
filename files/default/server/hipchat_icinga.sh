#!/bin/bash

# exit on failure
set -e

SCRIPT=`dirname "$0"`/hipchat_room_message.sh

case "$2" in
 "OK") COLOR="green" ;;
 "WARNING") COLOR="yellow" ;;
 "UNKNOWN") COLOR="purple" ;;
 "CRITICAL") COLOR="red" ;;

 "UP") COLOR="green" ;;
 "DOWN") COLOR="red" ;;
 "UNREACHABLE") COLOR="purple" ;;

 *) COLOR="red" ;;
esac

$SCRIPT -c $COLOR "${@:3}"
