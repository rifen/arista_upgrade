#!/bin/bash

################
## VARIABLES ##
################
response=${response,,}
failure_message=$(su -c "cvpi status" cvp | grep failed:)
amount_failed=${failure_message: -1}

################
## FUNCTIONS ##
################
check_cvp_fails() {
  if [[ amount_failed -gt 0 ]]; then
    su -c "cvpi status" cvp
    read -r -p "Are you sure you want to upgrade with failures? (y/n) " response
    if [[ "$response" =~ ^(no|n)$ ]]; then
      echo -e "Exiting CloudVision Portal upgrade script"
      exit 1   
    fi
  fi
}

upgrade_folder() {
  if ! [[ -f /tmp/upgrade ]]; then
    su -c "mkdir /tmp/upgrade" cvp
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
# Confirmation
read -r -p "Ready to upgrade from ${CVP_VERSION} to ${version} ?" response
if [[ "$response" =~ ^(no|n)$ ]]; then
      echo -e "Exitting CloudVision Portal upgrade script"
      exit 1
fi
# Based of version given extracts what the release is
release=${version::2}
# Performs the upgrade
cd su -c "./tmp/upgrade" || echo -en "Couldn't find the upgrade directory." && exit 1
su -c "curl -o cvp-upgrade-"${version}".tgz https://www.arista.com/custom_data/aws3-explorer/download-s3-file.php?f=/support/download/CloudVision/CloudVision%20Portal/Active%20Releases/"${release}"/"${version}"/cvp-upgrade-"${version}".tgz" || echo -en "Failed to curl the version ${version} from release ${release}" && exit 1
su -c "upgrade || quit" cvpadmin || exit 1 # This doesn't work but you will get into the cvpadmin prompt then you will need to press u or type upgrade