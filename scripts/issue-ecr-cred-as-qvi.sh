#!/bin/bash

##################################################################
##                                                              ##
##          Script for issuing legal entity ecr AS QVI          ##
##                                                              ##
##################################################################

PWD=$(pwd)
source $PWD/source.sh

# Capture password
passcode="$(get_passcode $1)"

printf "\n"
printf "------\n"
printf "This script is for the unusual case where you are issuing an ECR AS A QVI,\n"
printf "ON BEHALF OF A LEGAL ENTITY, and the LE has previously issued an ECR AUTH\n"
printf "credential. The more normal case is that the LE issues the credential itself,"
printf "which means less work from everyone. If you truly intend to issue an ECR as\n"
printf "QVI, proceed. Otherwise, press CTRL+C to cancel and run issue-ecr-cred-as-le\n"
printf "instead.\n"
printf "------\n"
printf "\n"

read -p "Enter the LEI of the new Legal Entity: " -r lei
read -p "Enter person legal name: " -r personLegalName
read -p "Enter engagement context role: " -r engagementContextRole
read -p "Enter the alias of the recipient of ECR credential: " -r recipient

# Create DATA block
echo "[\"${lei}\", \"${personLegalName}\", \"${engagementContextRole}\"]" | jq -f "${QAR_SCRIPT_DIR}/legal-entity-ecr-data.jq" > "${QAR_DATA_DIR}/legal-entity-ecr-data.json"

# Create EDGES block
auth_said=$(kli vc list --name "${QAR_NAME}" --passcode "${passcode}" --alias "${QAR_AID_ALIAS}" --said --schema EH6ekLjSr8V32WyFbGe1zXjTzFs9PkTYmupJ9H65O14g)

echo "\"${auth_said}\"" | jq -f "${QAR_SCRIPT_DIR}/legal-entity-ecr-edges-filter.jq" > "${QAR_DATA_DIR}/legal-entity-ecr-edge-data.json"
kli saidify --file data/legal-entity-ecr-edge-data.json

# Prepare the RULES section
cp "${QAR_SCRIPT_DIR}/rules.json" "${QAR_DATA_DIR}/rules.json"

filename="data/ecr.json"
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

kli vc issue --name "${QAR_NAME}" --passcode "${passcode}" --alias "${QAR_AID_ALIAS}" --registry-name "${QAR_REG_NAME}" --schema EBNaNu-M9P5cgrnfl2Fvymy4E_jvxxyjb70PRtiANlJy --recipient "${recipient}" --data @"data/legal-entity-ecr-data.json" --edges @"data/legal-entity-ecr-edge-data.json" --rules @"data/rules.json" --out "$filename"

# Make sure the s3 upload finishes.
wait