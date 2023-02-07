#!/bin/bash

##################################################################
##                                                              ##
##        Script for issuing legal entity credential            ##
##                                                              ##
##################################################################

PWD=$(pwd)
source $PWD/source.sh

# Capture password
passcode="$(get_passcode $1)"

read -p "Enter the LEI of the new Legal Entity: " -r lei
read -p "Enter the alias of the new Legal Entity: " -r recipient

# Create DATA block
echo "\"${lei}\"" | jq -f "${QAR_SCRIPT_DIR}/legal-entity-data.jq" > "${QAR_DATA_DIR}/legal-entity-data.json"

# Create EDGES block
qvi_said=$(kli vc list --name "${QAR_NAME}" --passcode "${passcode}" --alias "${QAR_AID_ALIAS}" --said --schema EBfdlu8R27Fbx-ehrqwImnK-8Cm79sqbAQ4MmvEAYqao)

echo "\"${qvi_said}\"" | jq -f "${QAR_SCRIPT_DIR}/legal-entity-edges-filter.jq" > "${QAR_DATA_DIR}/legal-entity-edge-data.json"
kli saidify --file data/legal-entity-edge-data.json

# Prepare the RULES section
cp "${QAR_SCRIPT_DIR}/rules.json" "${QAR_DATA_DIR}/rules.json"

filename="data/le.json"
# Make sure any pre-existing old credential isn't left laying around by mistake to confuse us.
if [ -f "$filename" ]; then
  mv "$filename" "${filename}.bak"
fi

# Automatically upload the newly generated ACDC to S3 so others can download it
# without this user having to start a new ssh session and run scp. This share
# script will start, move into the background to allow the kli vc issue command
# to run, and lurk up to 30 secs for the ACDC to appear. Once it appears, the
# script will automatically perform the upload and exit. The user will perceive
# the upload to happen after issuance. If the script fails for some reason, you
# can re-run: share-via-s3 upload --file data/ecr.json --now. This will cause it
# to immediately upload the file instead of waiting.
share-via-s3 upload --file "$filename" &

kli vc issue --name "${QAR_NAME}" --passcode "${passcode}" --alias "${QAR_AID_ALIAS}" --registry-name "${QAR_REG_NAME}" --schema ENPXp1vQzRF6JwIuS-mp2U8Uf1MoADoP_GqQ62VsDZWY --recipient "${recipient}" --data @"data/legal-entity-data.json" --edges @"data/legal-entity-edge-data.json" --rules @"data/rules.json" --out "$filename"
