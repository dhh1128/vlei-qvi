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

printf "\n"
printf "------\n"
printf "This script is for the unusual case where you, a LEGAL ENTITY, WANT AN ECR FOR\n"
printf "SOMEONE IN YOUR ORG TO BE ISSUED BY A QVI, INSTEAD OF YOU ISSUING IT DIRECTLY.\n"
printf "The more normal case is that the LE issues the credential itself, which means\n"
printf "less work from everyone, and still resolves to the same root of trust. If you\n"
printf "truly intend for the QVI to issue the ECR, proceed. Otherwise, press CTRL+C to\n"
printf "cancel, skip the auth cred step, and run issue-ecr-cred-as-le instead.\n"
printf "------\n"
printf "\n"

read -p "Enter your LEI : " -r lei
read -p "Enter or Paste the AID of the recipient of the OOR credential: " -r AID
read -p "Enter requested person legal name: " -r personLegalName
read -p "Enter requested engagement context role: " -r engagementContextRole

# Prepare DATA Section
echo "[\"${AID}\", \"${lei}\", \"${personLegalName}\", \"${engagementContextRole}\"]" | jq -f "${QAR_SCRIPT_DIR}/ecr-auth-data.jq" > "${QAR_DATA_DIR}/ecr-auth-data.json"

read -p "Enter AID of QVI : " -r recipient

# Prepare the EDGES Section
le_said=$(kli vc list --name "${QAR_NAME}" --passcode "${passcode}" --alias "${QAR_AID_ALIAS}" --said --schema ENPXp1vQzRF6JwIuS-mp2U8Uf1MoADoP_GqQ62VsDZWY  | tr -d '\r')

echo "\"${le_said}\"" | jq -f "${QAR_SCRIPT_DIR}/ecr-auth-edges-filter.jq" > "${QAR_DATA_DIR}/ecr-auth-edge-data.json"
kli saidify --file data/ecr-auth-edge-data.json

filename="data/ecr-auth.json"
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

kli vc issue --name "${QAR_NAME}" --passcode "${passcode}" --alias "${QAR_AID_ALIAS}" --registry-name "${QAR_REG_NAME}" --schema ED_PcIn1wFDe0GB0W7Bk9I4Q_c9bQJZCM2w7Ex9Plsta --recipient "${recipient}" --data @"data/ecr-auth-data.json" --edges @"data/ecr-auth-edge-data.json" --rules @"data/rules.json" --out "$filename"

# Make sure the s3 upload finishes.
wait