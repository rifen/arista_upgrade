#!/bin/bash

if [[ "$(whoami)" != root ]]; then
  echo "Only user root can run this script."
  exit 1
fi

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
  if ! [[ -e /tmp/upgrade ]]; then
    su -c "mkdir /tmp/upgrade" cvp
  else
    read -r -p "Do you want to remove everything in /tmp/upgrade? *You must remove everything from /tmp/upgrade to upgrade* (y/n): " response
    if [[ "$response" =~ ^(no|n)$ ]]; then
      echo -e "Exitting CloudVision Portal upgrade script *You must remove everything from /tmp/upgrade to upgrade*"
      exit 1
    else
      rm -rf /tmp/upgrade/*
    fi
  fi
}
###########
## LOGIC ##
###########

# First checks if anything is failing if failure message grep isn't empty
if [[ -n "$failure_message" ]]; then
  check_cvp_fails
else
  echo -en "CVP is in good health. Continuing..."
fi

# Looks for the /tmp/upgrade folder and creates or clears it.
upgrade_folder

# Run a backup before upgrading
echo -e "Running backups first..."
su -c "timeout --preserve-status 120s cvpi backup cvp  &" cvp || echo -en "Couldn't execute cvpi backup cvp" && exit 1
./cvpi/tools/backup.sh || echo -en "Couldn't execute ./cvpi/tools/backup.sh backup completely" && exit 1
echo -e "Backup complete"

# Asks for which version is needed
read -r -p "Enter the version of CloudVision Portal(eg. 2021.1.0): " version
# Based of version given extracts what the release is
release=${version::2}

# Confirmation
read -r -p "Ready to upgrade from ${CVP_VERSION} to ${version}? (y/n):" response
if [[ "$response" =~ ^(no|n)$ ]]; then
      echo -e "Exitting CloudVision Portal upgrade script"
      exit 1
elif [[ "$response" =~ ^(yes|y)$ ]]; then
      echo -e "Upgrading to ${version}"
else
      echo -e "Invalid input only *yes | y | no | n* allowed"
      exit 1
fi

# Downloads the version specified
cd su -c "./tmp/upgrade" cvp || echo -en "Couldn't find the upgrade directory." && exit 1
su -c "curl -o cvp-upgrade-""${version}"".tgz https://www.arista.com/custom_data/aws3-explorer/download-s3-file.php?f=/support/download/CloudVision/CloudVision%20Portal/Active%20Releases/""${release}""/""${version}""/cvp-upgrade-""${version}"".tgz" || echo -en "Failed to curl the version ${version} from release ${release}" cvp && exit 1

# Performs Upgrade
if  [[ -e "/tmp/upgrade/cvp-upgrade-${version}" ]]; then
  su -c "upgrade || quit" cvpadmin || exit 1 # This doesn't work but you will get into the cvpadmin prompt then you will need to press u or type upgrade
fi