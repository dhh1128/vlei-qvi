#!/bin/bash

##################################################################
##                                                              ##
##      Script for generating random challenge phrase           ##
##                                                              ##
##################################################################

PWD=$(pwd)
source $PWD/source.sh

# Capture password
passcode=$(get_passcode $1)

printf "Acting as %s. Use set-person or generate-challenge-as to change.\n\n" "$OWNER"

read -p "Enter the alias you want to authenticate: " -r other_party
echo " "

kli challenge verify --generate --out string --name "${QAR_NAME}" --passcode "${passcode}" --alias "${QAR_ALIAS}" --signer "${other_party}"
