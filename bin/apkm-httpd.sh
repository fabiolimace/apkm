#!/bin/bash

#
# Runs the Busybox httpd server.
#
# Usage:
#
#     apkm-http-server.sh
#
# Configuration:
#
#     # file .apkm/conf.txt
#     busybox.httpd.bind=127.0.0.1:9000
#

source "`dirname "$0"`/apkm-common.sh" || exit 1;
validate_program_and_working_paths || exit 1;

PROPERTY_BIND="busybox.httpd.bind"
PROPERTY_BIND_DEFAULT=127.0.0.1:9000

function busybox_httpd_bind {
    local PROPERTY_BIND="busybox.httpd.bind"
    local BIND=`grep -E "^$PROPERTY_BIND" "$WORKING_DIR/.apkm/conf.txt" | sed "s/$PROPERTY_BIND=//"`;
    if [[ -n "$BIND" ]];
    then
        echo $BIND;
    else
        echo $PROPERTY_BIND_DEFAULT;
    fi;
}

function busybox_httpd_stop {
    local PID=`ps aux | grep 'busybox httpd' | grep -v "grep" | awk '{print $2}'`
    if [[ "$PID" -gt 1024 ]];
    then
        kill -9 $PID;
    fi;
}

function busybox_httpd_start {
    local BIND=`busybox_httpd_bind`;
    busybox httpd -p "$BIND" -h "$WORKING_DIR/.apkm/html/"
}

busybox_httpd_stop;
busybox_httpd_start;

