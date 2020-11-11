#!/bin/bash

# Script for appending to the user community sample table
# https://github.com/MycroftAI/enclosure-picroft/wiki/User-Community-Pi-Samples
# Outputs reST table CSV syntax

# Easy YYYY-MM-DD format
DATE="$(date +%F)"

# Standardized way to get human readable pi versioning
# (use tr to supress null byte warning)
PI_VERSION="$(tr -d '\0' </proc/device-tree/model)"

# Best way AFAICT to determine the enclosure-picroft version (update scripts update this file)
PICROFT_VERSION="$(cat ${HOME}/version)"

# Determine the mycroft-core version
MYCROFT_CORE_VERSION="$(python -c 'from mycroft import version; v=version.VersionManager.get(); print(v["coreVersion"])')"

# Grab CPU thermal temp and convert to celsius
CPU="$(</sys/class/thermal/thermal_zone0/temp)"
CPU_TEMP="$((CPU/1000))'C"

# Use 'vc' to determine GPU temp in celsius
GPU_TEMP="$(/opt/vc/bin/vcgencmd measure_temp | awk -F= '{print $2}')"

# Use 'vc' to determine if we're being throttled
PI_THROTTLING="$(vcgencmd get_throttled | awk -F\= '{print $2}')"

# Use 'w' and print the standard system load averages (1/5/15 minutes)
LOAD_AVGS="$(w | grep load | awk -F'load average:' '{print $2}')"

# Print the CSV rST format for table
echo
echo "   DATE, PI VERSION, MYCROFT CORE VERSION, PICROFT VERSION, PI HW THERMAL MANAGEMENT, PI HW CASE, CPU TEMP, GPU TEMP, PI THROTTLING, LOAD AVGS, USER"
echo "   \"${DATE}\", \"${PI_VERSION}\", \"${MYCROFT_CORE_VERSION}\", \"${PICROFT_VERSION}\", \"<UPDATE_PI_HW>\", \"<UPDATE_PI_CASE>\", \"${CPU_TEMP}\", \"${GPU_TEMP}\", \"${PI_THROTTLING}\", \"${LOAD_AVGS}\", \"<UPDATE_USER>\""
echo

# Print bonus info about culprit processor
echo
ps aux | head -1; ps haux | sort -nrk 3,3 | head -n 10
echo
