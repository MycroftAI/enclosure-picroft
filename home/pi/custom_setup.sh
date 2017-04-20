#!/bin/bash
##########################################################################
# custom_setup.sh
##########################################################################
# You can use this script to execute custom actions on startup.  It gets
# called by auto_run.sh.  This file will never be replaced by an update.

# Use WakeOnLan (WOL) to wake any other machines, eg: your DLNA server
# wakeonlan [xxMACADDRESS] # eg: 11:22:33:44:55:66

# A More complex WOL script:
# VAR=`ping -s 1 -c 2 xxHOSTNAME > /dev/null; echo $?`
# if [ $VAR -eq 0 ];then
#   echo -e "xxHOSTNAME is UP as on $(date)"
#   elif [ $VAR -eq 1 ];then
#   wakeonlan xxMACADDRESS | echo "xxHOSTNAME not turned on. WOL packet sent at $(date +%H:%M)"
#   sleep 3m | echo "Waiting 3 Minutes"
#   PING=`ping -s 1 -c 4 xxHOSTNAME > /dev/null; echo $?`
#   if [ $PING -eq 0 ];then
#     echo "xxHOSTNAME is UP as on $(date +%H:%M)"
#   else
#     echo "xxHOSTNAME not turned on - Please Check Network Connections"
#   fi
# fi

# Do anything else you want to on startup!
#speak "It is so good to be back online!"
