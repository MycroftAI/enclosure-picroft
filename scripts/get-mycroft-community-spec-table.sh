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

# Use 'w' and print the standard system load averages (1/5/15 minutes)
LOAD_AVGS="$(w | grep load | awk -F'load average:' '{print $2}')"

# Print the CSV rST format for table
echo
echo "   \"${DATE}\", \"${PI_VERSION}\", \"${MYCROFT_CORE_VERSION}\", \"${PICROFT_VERSION}\", \"<UPDATE>\", \"<UPDATE>\", \"${CPU_TEMP}\", \"${GPU_TEMP}\", \"${LOAD_AVGS}\", \"<USER>\""
echo

