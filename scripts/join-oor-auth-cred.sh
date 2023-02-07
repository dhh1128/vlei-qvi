#!/bin/bash

##################################################################
##                                                              ##
##          Script for issuing ecr auth                         ##
##                                                              ##
##################################################################

PWD=$(pwd)
source $PWD/source.sh

# Capture password
passcode=$(get_passcode $1)

filename="data/oor-auth.json"
# Make sure any pre-existing old credential isn't left laying around by mistake to confuse us.
if [ -f "$filename" ]; then
  mv "$filename" "${filename}.bak"
fi

read -p "Enter the name on S3 of the new credential: " -r obj

# Download the newly generated ACDC from S3 so we can use it to
# join, without having to start a new ssh session and run scp.
share-via-s3 download --obj "$obj" --file "$filename"

kli vc issue --name "${QAR_NAME}" --passcode "${passcode}" --alias "${QAR_AID_ALIAS}" --credential @"${filename}"
