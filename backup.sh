#!/bin/bash
# Makes sure the envvars are present and assigns them.
log=$HOME/log.txt
. $HOME/.bash_profile
if [ -z "${AWS_ACCESS_KEY:-}" ]; then
  echo 'AWS_ACCESS_KEY/AWS_SECRET_KEY envvars not set. export AWS_ACCESS_KEY="" && export AWS_SECRET_KEY=""' >> "$log"
  exit 1
else
  awsAccess="${AWS_ACCESS_KEY}"
  awsSecret="${AWS_SECRET_KEY}"
fi

printf "\nLog File - " >> "$log"
date >> "$log"
today=$(date +"%Y-%m-%d")
slack_message() {
  # Slack Function that sends a message to sdn-alerts
  message="$1"
  slack_web_url="" # NEED TO GET SLACK WEB URL
  escapedText=$(echo "$message" | sed 's/"/\"/g' | sed "s/'/\'/g")
  json="{\"text\": \"$escapedText\"}"
  response=$(curl -i -H "Content-Type: application/json" -d "$json" "$slack_web_url")
  echo -en "\nSlack ### - \n$response\n###" >> "$log"
}

# Define where the file is and zip it together for transfer
filename="cvp-backup-$today.zip"
backup_path="/data/cvpbackup"
temp_store="$HOME/$filename"
if [[ ! -f $temp_store ]]; then
  zip -r "$temp_store" $backup_path
fi

echo -en "Backing up $temp_store\n"

# S3 Bucket initializion and curl of the .zip we created to the cvp-bucket

bucket='cvp-backup-test'
folder="cvp-backup"
aws_path="/$bucket/$folder/$filename"
date=$(date +"%a, %d %b %Y %T %z")
content_type='application/zip'
string="PUT\n\n$content_type\n$date\n$aws_path"
signature=$(echo -en "${string}" | openssl sha1 -hmac "$awsSecret" -binary | base64)

response=$(curl -v -i -X PUT -T "$temp_store" \
  -H "Host: $bucket.s3.amazonaws.com" \
  -H "Date: $date" \
  -H "Content-Type: $content_type" \
  -H "Authorization: AWS $awsAccess:$signature" \
  "https://$bucket.s3.amazonaws.com/$folder/$filename") || \
  slack_message "The backup from $HOSTNAME to $bucket bucket has failed" && echo -en "$response" >> "$log"
if  [[ $response != *"200"* ]]; then
  slack_message "The backup from $HOSTNAME to $bucket bucket has failed" && echo -en "$response" >> "$log"
  exit 1
fi
slack_message "$HOSTNAME has backed up $filename to the $bucket bucket." && echo -en "$response" >> "$log"

# Remove the temp zip file
rm "$temp_store"

# Clean Exit
exit 0
