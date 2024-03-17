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
#     busybox.httpd.port=127.0.0.1:9000
#

source "`dirname "$0"`/apkm-common.sh" || exit 1;
validate_program_and_working_paths || exit 1;

PROPERTY_PORT="busybox.httpd.port"
PROPERTY_PORT_DEFAULT=127.0.0.1:9000

function busybox_httpd_port {
    local PORT=`grep -E "^$PROPERTY_PORT" "$WORKING_DIR/.apkm/conf.txt" | sed "s/$PROPERTY_PORT=//"`;
    if [[ -n "$PORT" ]];
    then
        echo $PORT;
    else
        echo $PROPERTY_PORT_DEFAULT;
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
    local PORT=`busybox_httpd_port`;
    busybox httpd -p "$PORT" -h "$WORKING_DIR/.apkm/html/"
}

busybox_httpd_stop;
busybox_httpd_start;

