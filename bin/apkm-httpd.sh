#!/bin/sh

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

. "`dirname "$0"`/apkm-common.sh";

property_port="busybox.httpd.port"
property_port_default="127.0.0.1:9000"

busybox_httpd_port() {
    local port=`grep -E "^${property_port}" "${WORKING_DIR}/.apkm/conf.txt" | sed "s/${property_port}=//"`;
    if [ -n "${port}" ]; then
        echo "${port}";
    else
        echo "${property_port_default}";
    fi;
}

busybox_httpd_stop() {
    local pid=`ps aux | grep 'busybox httpd' | grep -v "grep" | awk '{ print $2 }'`
    if [ -n "$pid" ] && [ "$pid" -gt 1024 ]; then
        kill -9 $pid;
    fi;
}

busybox_httpd_start() {
    local port=`busybox_httpd_port`;
    busybox httpd -p "$port" -h "$WORKING_DIR/.apkm/html/"
    echo Listening: "http://$port"
}

main() {
    busybox_httpd_stop;
    busybox_httpd_start;
}

main;

