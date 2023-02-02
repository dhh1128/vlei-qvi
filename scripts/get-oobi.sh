#!/bin/bash

##################################################################
##                                                              ##
##      Script for listing aliases for remote contacts          ##
##                                                              ##
##################################################################

PWD=$(pwd)
source $PWD/source.sh

# Capture password
passcode=$(get_passcode $1)

echo ""
#kli contacts list --name "${QAR_NAME}" --passcode "${passcode}" | jq '"Alias: "+.alias+"\n\rAID:   "+.id+"\n\rOOBI: "+.oobi+"\n\rAuthenticated: "+ if .challenges | length > 0 then "True" else "False" end +"\n\r"' --raw-output

OOBI=`kli contacts list --name "${QAR_NAME}" --passcode "${passcode}" | jq '.oobi' --raw-output`
echo "$OOBI"