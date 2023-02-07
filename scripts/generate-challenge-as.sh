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

read -p "Generate the challenge as which alias? " -r as
read -p "Enter the alias you want to authenticate: " -r other_party
echo " "
kli challenge verify --generate --out string --name "${QAR_NAME}" --passcode "${passcode}" --alias "${as}" --signer "${other_party}"
