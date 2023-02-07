#!/bin/bash

##################################################################
##                                                              ##
##          Script for joining legal entity ecr                 ##
##                                                              ##
##################################################################

PWD=$(pwd)
source $PWD/source.sh

# Capture password
passcode="$(get_passcode $1)"

# Capture password
passcode="$(get_passcode $1)"

# Make sure old credential isn't left laying around by mistake to confuse us.
rm -f data/ecr.json

read -p "Enter the name on S3 of the new credential: " -r obj

# Download the newly generated ACDC from S3 so we can use it to
# join, without having to start a new ssh session and run scp.
share-via-s3 download --obj "$obj" --file data/ecr.json

kli vc issue --name "${QAR_NAME}" --passcode "${passcode}" --alias "${QAR_AID_ALIAS}" --credential @"${filename}"

