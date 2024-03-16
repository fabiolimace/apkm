#!/usr/bin/env bash
#
# Wrapper for the real APKM main program
#
# See: http://mywiki.wooledge.org/BashFAQ/028
#

if [[ -e "~/.apkm.conf" ]];
then
    source "~/.apkm.conf";
elif [[ -e "/etc/apkm.conf" ]];
then
    source "/etc/apkm.conf";
fi;

exec "$APKM_HOME/bin/apkm" || {
    echo 1>&2 'Could not execute "$APKM_HOME/bin/apkm".\n'
    exit 1
}

