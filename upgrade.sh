#!/bin/bash

# Check to make sure the cvp user is the user and if 
if ! [[ $USER == "cvp" ]]; then
echo -en "Switching to the cvp user."
  su cvp
else
  echo -en "This script needs to execute as the cvp user if that doesn't exist this won't work."
  exit 1
fi

################
## VARIABLES ##
################
response=${response,,}
failure_message=$(cvpi status | grep failed:)
amount_failed=${failure_message: -1}

################
## FUNCTIONS ##
################
check_cvp_fails() {
  if [[ amount_failed -gt 0 ]]; then
    cvpi status
    read -r -p "Are you sure you want to upgrade with failures? (y/n) " response
    if [[ "$response" =~ ^(no|n)$ ]]; then
      echo -e "Exitting CloudVision Portal upgrade script"
      exit 1   
    fi
  fi
}

upgrade_folder() {
  if ! [[ -f /tmp/upgrade ]]; then
    mkdir /tmp/upgrade
  else
    read -r -p "Do you want to remove everything in /tmp/upgrade? (y/n) " response
    if [[ "$response" =~ ^(no|n)$ ]]; then
      echo -e "Exitting CloudVision Portal upgrade script"
      exit 1
    else
      rm -rf /tmp/upgrade/*
    fi
  fi
}
###########
## LOGIC ##
###########

# First checks if anything is failing
check_cvp_fails
# Looks for the /tmp/upgrade folder and creates or clears it.
upgrade_folder
# Asks for which version is needed
read -r -p "Enter the version of CloudVision Portal(eg. 2021.1.0): " version
# Based of version given extracts what the release is
release=${version::2}
# Performs the upgrade
cd ./tmp/upgrade || exit 1
curl -o cvp-upgrade-"${version}".tgz https://www.arista.com/custom_data/aws3-explorer/download-s3-file.php?f=/support/download/CloudVision/CloudVision%20Portal/Active%20Releases/"${release}"/"${version}"/cvp-upgrade-"${version}".tgz || exit 1
su -c upgrade cvpadmin || exit 1
u || quit
