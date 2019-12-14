#!/bin/bash
set -e

if [[ "$1" = 'start-confluence' ]]; then
    exec /opt/atlassian/confluence/bin/start-confluence.sh -fg
else
    exec "$@"
fi