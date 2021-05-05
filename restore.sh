#!/bin/bash
response=${response,,}

if [[ -n $CVP_MODE ]]; then
  echo -e "CVP is configured"
  read -r -p "What is the date you want to restore to?(eg. 2021-04-30): " response
  recover_date=response
else
  echo -e "CVP needs to be configured because CVP_MODE environment variable is blank"
  exit 1
fi

default_dir="/data/cvpbackup/"
awsAccess="${AWS_ACCESS_KEY}"
awsSecret="${AWS_SECRET_KEY}"
filename="cvp-backup-${recover_date}.zip"
file="cvp-backup/${filename}"
bucket='cvp-backup-test'
resource="/${bucket}/${file}"
contentType="application/x-compressed-tar"
date=$(date +"%a, %d %b %Y %T %z")
string="GET\n\n${contentType}\n${date}\n${resource}"
signature=$(echo -en "${string}" | openssl sha1 -hmac "$awsSecret" -binary | base64)
wget -O ${filename} --header="Host: ${bucket}.s3.amazonaws.com" \
--header="Date: ${date}" \
--header="Content-Type: ${contentType}" \
--header="Authorization: AWS ${awsAccess}:${signature}" \
"https://${bucket}.s3.amazonaws.com/${file}" || echo -en "Failed to GET $filename from the $bucket bucket"
cd $default_dir || exit
unzip -j ${filename}
eos=$(ls $default_dir | grep eos)
tar=$(ls -Art $default_dir| tail -n 1)
echo -e "You must now run: cvpi restore cvp $tar $eos"
