#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

#####################################################################
#                                                                   #
# Script:  bashunit_load.sh                                         #
#                                                                   #
# Purpose: Triggered by NPM's install event, this script            #
#          downloads bashunit to ../lib (relative path),            #
#          which is the default dir for bashunit.                   #
#                                                                   #
# Date:    10th May 2025                                            #
#                                                                   #
# Author:  admin <admin@datr.tech>                                  #
#                                                                   #
#####################################################################

#####################################################################
#                                                                   #
# CORE SECTIONS (within the code below)                             #
#                                                                   #
#                                                                   #
# 1 ENV VAR AND DEPENDENCY DEFINITIONS                              #
#                                                                   #
# 1.1  SCRIPT CONSTANTS                                             #
# 1.2  DEFINE THE REQUIRED SCRIPT DEPENDENCIES                      #
# 1.3  DEFINE THE REQUIRED ENV VARS                                 #
# 1.4  DEFINE THE CONF FILE PATH                                    #
#                                                                   #
#                                                                   #
# 2 DEPENDENCY AND PATH CHECKS                                      #
#                                                                   #
# 2.1 CHECK THE REQUIRED SCRIPT DEPENDENCIES                        #
# 2.2 CHECK THE CONF FILE PATH                                      #
#                                                                   #
#                                                                   #
# 3 LOAD AND CHECK ENV VARS                                         #
#                                                                   #
# 3.1 LOAD ENV VARS                                                 #
# 3.2 CHECK THE REQUIRED ENV VARS                                   #
#                                                                   #
#                                                                   #
# 4 INSTALL BASHUNIT                                                #
#                                                                   #
#####################################################################

#####################################################################
#####################################################################
#                                                                   #
#                                                                   #
# 1 ENVIRONMENT VARIABLE AND DEPENDENCY DEFINITIONS                 #
#                                                                   #
#                                                                   #
#####################################################################
#####################################################################

#####################################################################
#                                                                   #
# 1.1 SCRIPT CONSTANTS                                              #
#                                                                   #
#####################################################################

declare -r SCRIPT_FILE_NAME="bashunit_load.sh"

ROOT_DIR="$(dirname "${BASH_SOURCE[-1]}")/.."
readonly ROOT_DIR

#####################################################################
#                                                                   #
# 1.2 DEFINE THE REQUIRED SCRIPT DEPENDENCIES                       #
#                                                                   #
#####################################################################

declare -a -r SCRIPT_FILE_REQUIRED_DEPENDENCIES=(
  "curl"
  "realpath"
  "source"
)

#####################################################################
#                                                                   #
# 1.3 DEFINE THE REQUIRED ENV VARS                                  #
#                                                                   #
#####################################################################

declare -a -r SCRIPT_FILE_REQUIRED_ENV_VARS=(
  "BASHUNIT_REPO_URL"
)

#####################################################################
#                                                                   #
# 1.4 DEFINE THE CONF FILE PATH                                     #
#                                                                   #
#####################################################################

declare -r CONF_FILE_NAME=".bashunit.conf"
declare -r CONF_FILE_PATH="${ROOT_DIR}/${CONF_FILE_NAME}"

#####################################################################
#####################################################################
#                                                                   #
#                                                                   #
# 2 DEPENDENCY AND PATH CHECKS                                      #
#                                                                   #
#                                                                   #
#####################################################################
#####################################################################

#####################################################################
#                                                                   #
# 2.1 CHECK THE REQUIRED SCRIPT DEPENDENCIES                        #
#                                                                   #
#####################################################################

declare required_dependency

for required_dependency in "${SCRIPT_FILE_REQUIRED_DEPENDENCIES[@]}"; do
  if ! command -v "${required_dependency}" > /dev/null 2>&1; then
    echo "${SCRIPT_FILE_NAME}: ${required_dependency}: not found" >&2
    exit 1
  fi
done

#####################################################################
#                                                                   #
# 2.2 CHECK THE CONF FILE PATH                                      #
#                                                                   #
#####################################################################

if [ ! -f "${CONF_FILE_PATH}" ]; then
  echo "CONF_FILE_PATH: invalid"
  exit 1
fi

#####################################################################
#####################################################################
#                                                                   #
#                                                                   #
# 3 LOAD AND CHECK ENV VARS                                         #
#                                                                   #
#                                                                   #
#####################################################################
#####################################################################

#####################################################################
#                                                                   #
# 3.1 LOAD ENV VARS                                                 #
#                                                                   #
#####################################################################

# shellcheck source=.env
source "${CONF_FILE_PATH}"

#####################################################################
#                                                                   #
# 3.2 CHECK THE REQUIRED ENV VARS                                   #
#                                                                   #
#####################################################################

declare required_env_var

for required_env_var in "${SCRIPT_FILE_REQUIRED_ENV_VARS[@]}"; do
  #
  # Note the use of 'indirect variable expansion' below.
  #
  if [ -z "${!required_env_var}" ]; then
    echo "${SCRIPT_FILE_NAME}: ${required_env_var}: not found" >&2
    exit 1
  fi
done

#####################################################################
#####################################################################
#                                                                   #
#                                                                   #
# 4 INSTALL BASHUNIT                                                #
#                                                                   #
#                                                                   #
#####################################################################
#####################################################################

curl -s "${BASHUNIT_REPO_URL}" | bash
