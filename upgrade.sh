#!/bin/bash

################
## VARIABLES ##
################
response=${response,,}
failure_message=$(cvpi status | grep failed:)
amount_failed=$(echo "${failure_message: -1}")

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
  rm -rf /tmp/upgrade/*
fi
}
###########
## LOGIC ##
###########

# First checks if anything 
check_cvp_fails
upgrade_folder
read -r -p "Enter the version of CloudVision Portal(eg. 2021.1.0): " version
release=${echo ${version::2}}
cd /tmp/upgrade
curl -o cvp-upgrade-${version}.tgz https://www.arista.com/custom_data/aws3-explorer/download-s3-file.php?f=/support/download/CloudVision/CloudVision%20Portal/Active%20Releases/${release}/${version}/cvp-upgrade-${version}.tgz
