#!/usr/bin/env bash

set -euo pipefail

#####################################################################
#                                                                   #
# Script:  bootstrap.sh                                             #
#                                                                   #
# Purpose: Bootstraps common functions for the Bashunit tests       #
#          Bashunit finds the path to the this file from the        #
#          BASHUNIT_BOOTSTRAP var within the .env file in the       #
#          project root.                                            #
#                                                                   #
# Date:    13th February 2025 (revised)                             #
#                                                                   #
# Author:  admin <admin@datr.tech>                                  #
#                                                                   #
#####################################################################

#####################################################################
#                                                                   #
# CORE SECTIONS (within the code below)                             #
#                                                                   #
#                                                                   #
# 1 SCRIPT PERMISSIONS AND DEPENDENCY CHECKS                        #
#                                                                   #
# 1.1 CHECK SCRIPT PERMISSIONS                                      #
# 1.2 SCRIPT CONSTANTS                                              #
# 1.3 DEFINE THE REQUIRED SCRIPT AND TEST DEPENDENCIES              #
# 1.4 CHECK THE REQUIRED SCRIPT AND TEST DEPENDENCIES               #
# 1.5 DEFINE THE REQUIRED ENV VARS (from .env)                      #
# 1.6 CHECK THE REQUIRED ENV VARS                                   #
# 1.7 PRINT AVAILABLE ENV VARS                                      #
# 1.8 CHECK BOOTSTRAP_SCRIPT_MAILDIR_ROOT_SQL_PATH                  #
#                                                                   #
#                                                                   #
# 2 COMMON FUNCTIONS (which can be called from the test files)      #
#                                                                   #
# (ordered alphabetically)                                          #
#                                                                   #
# 2.1  bootstrap__clear_exim_queue                                  #
# 2.2  bootstrap__generate_message_data                             #
# 2.3  bootstrap__generate_message_envelope                         #
# 2.4  bootstrap__generate_message_subject                          #
# 2.5  bootstrap__get_cert_dir                                      #
# 2.6  bootstrap__get_maildir_latest_email                          #
# 2.7  bootstrap__get_maildir_latest_email_path                     #
# 2.8  bootstrap__get_maildir_path                                  #
# 2.9  bootstrap__get_maildir_root                                  #
# 2.10 bootstrap__get_num_queued_messages                           #
# 2.11 bootstrap__get_root_dir                                      #
# 2.12 bootstrap__rm_maildir_emails                                 #
# 2.13 bootstrap__trim                                              #
#                                                                   #
#####################################################################

#####################################################################
#####################################################################
#                                                                   #
#                                                                   #
# 1 SCRIPT PERMISSIONS AND DEPENDENCY CHECKS                        #
#                                                                   #
#                                                                   #
#####################################################################
#####################################################################

#####################################################################
#                                                                   #
# 1.1 CHECK SCRIPT PERMISSIONS                                      #
#                                                                   #
#####################################################################

if [[ $EUID -ne 0 ]]; then
  echo "use: sudo make test"
  exit 1
fi

#####################################################################
#                                                                   #
# 1.2 SCRIPT CONSTANTS                                              #
#                                                                   #
#####################################################################

declare -r BOOTSTRAP_SCRIPT_NAME="bootstrap.sh"

BOOTSTRAP_SCRIPT_TMP_DATA_FILE="./BOOTSTRAP_SCRIPT_TMP_DATA_FILE_$(date +%s)"
readonly BOOTSTRAP_SCRIPT_TMP_DATA_FILE

BOOTSTRAP_SCRIPT_ROOT_DIR="$(dirname "${BASH_SOURCE[-1]}")/.."
readonly BOOTSTRAP_SCRIPT_ROOT_DIR

#####################################################################
#                                                                   #
# 1.3 DEFINE THE REQUIRED SCRIPT AND TEST DEPENDENCIES              #
#                                                                   #
#####################################################################

declare -a -r BOOTSTRAP_SCRIPT_AND_TEST_FILE_REQUIRED_DEPENDENCIES=(
  "awk"
  "column"
  "cut"
  #"dovecot"
  "echo"
  #"exim"
  "expect"
  "grep"
  "head"
  #"mariadb"
  #"named"
  "nslookup"
  "printf"
  "sed"
  "sort"
  "swaks"
  "wc"
  "xargs"
)

#####################################################################
#                                                                   #
# 1.4 CHECK THE REQUIRED SCRIPT AND TEST DEPENDENCIES               #
#                                                                   #
####################################################################:#

declare required_dependency

for required_dependency in "${BOOTSTRAP_SCRIPT_AND_TEST_FILE_REQUIRED_DEPENDENCIES[@]}"; do
  if ! command -v "${required_dependency}" > /dev/null 2>&1; then
    echo "${BOOTSTRAP_SCRIPT_NAME}: ${required_dependency}: not found" >&2
    exit 1
  fi
done

#####################################################################
#                                                                   #
# 1.5 DEFINE THE REQUIRED ENV VARS (from .env)                      #
#                                                                   #
#####################################################################

declare -a -r BOOTSTRAP_SCRIPT_REQUIRED_ENV_VARS=(
  "BOOTSTRAP_AUTH_LOGIN"
  "BOOTSTRAP_AUTH_PLAIN"
  "BOOTSTRAP_AUTH_UNSUPPORTED"
  "BOOTSTRAP_DOMAIN"
  "BOOTSTRAP_DOMAIN_LOCAL"
  "BOOTSTRAP_DOMAIN_MAILDIR"
  "BOOTSTRAP_EMAIL_ADMIN_LOCAL"
  "BOOTSTRAP_EMAIL_ADMIN_DOMAIN"
  "BOOTSTRAP_EMAIL_FILE_NAME_SUFFIX"
  "BOOTSTRAP_EMAIL_TEST_LOCAL"
  "BOOTSTRAP_EMAIL_REMOTE"
  "BOOTSTRAP_EMAIL_TEST_LOCAL_ALIAS_1"
  "BOOTSTRAP_EMAIL_TEST_LOCAL_ALIAS_2"
  "BOOTSTRAP_EMAIL_TEST_DOMAIN"
  "BOOTSTRAP_EMAIL_TEST_DOMAIN_ALIAS_1"
  "BOOTSTRAP_EMAIL_TEST_DOMAIN_ALIAS_2"
  "BOOTSTRAP_EXIM_SECURE_PORT"
  "BOOTSTRAP_EXIM_TLSC_PORT"
  "BOOTSTRAP_EXIM_UNSECURE_PORT"
  "BOOTSTRAP_IMAP_UNSECURE_PORT"
  "BOOTSTRAP_MAILDIR_NEW_EMAILS_DIR"
  "BOOTSTRAP_MAILDIR_ROOT_SQL_FILE_NAME"
  "BOOTSTRAP_TLS_1_1"
  "BOOTSTRAP_TLS_1_2"
  "BOOTSTRAP_TLS_1_3"
  "BOOTSTRAP_USER_ADMIN"
  "BOOTSTRAP_USER_TEST"
  "BOOTSTRAP_USER_TEST_PASS"
  "BOOTSTRAP_USER_TEST_PASS_INVALID"
  "BOOTSTRAP_USER_TEST_ALIAS_ONE"
  "BOOTSTRAP_USER_TEST_ALIAS_TWO"
)

#####################################################################
#                                                                   #
# 1.6 CHECK THE REQUIRED ENV VARS                                   #
#                                                                   #
#####################################################################

declare required_env_var

for required_env_var in "${BOOTSTRAP_SCRIPT_REQUIRED_ENV_VARS[@]}"; do
  #
  # Note the use of 'indirect variable expansion' below.
  #
  if [ -z "${!required_env_var}" ]; then
    echo "${BOOTSTRAP_SCRIPT_NAME}: ${required_env_var}: not found" >&2
    exit 1
  fi
done

#####################################################################
#                                                                   #
# 1.7 PRINT AVAILABLE ENV VARS                                      #
#                                                                   #
#####################################################################

echo -e "\n"
echo "AVAILABLE ENV VARS (for use in any unit test)"
echo "---------------------------------------------"

for i in "${!BOOTSTRAP_SCRIPT_REQUIRED_ENV_VARS[@]}"; do
  required_env_var="${BOOTSTRAP_SCRIPT_REQUIRED_ENV_VARS[$i]}"
  echo "$i,${required_env_var},${!required_env_var}" >> "${BOOTSTRAP_SCRIPT_TMP_DATA_FILE}"
done

column --table -s "," --table-columns ITEM,ENV_VAR,VALUE < "${BOOTSTRAP_SCRIPT_TMP_DATA_FILE}"
echo -e "\n"
rm -f "${BOOTSTRAP_SCRIPT_TMP_DATA_FILE}"

#####################################################################
#                                                                   #
# 1.8 CHECK BOOTSTRAP_SCRIPT_MAILDIR_ROOT_SQL_PATH                  #
#                                                                   #
#####################################################################

declare -r BOOTSTRAP_SCRIPT_MAILDIR_ROOT_SQL_PATH="${BOOTSTRAP_SCRIPT_ROOT_DIR}/sql/${BOOTSTRAP_MAILDIR_ROOT_SQL_FILE_NAME:?}"

if [ ! -f "${BOOTSTRAP_SCRIPT_MAILDIR_ROOT_SQL_PATH}" ]; then
  echo "${BOOTSTRAP_SCRIPT_NAME}: BOOTSTRAP_SCRIPT_MAILDIR_ROOT_SQL_PATH: not found" >&2
  exit 1
fi

#####################################################################
#####################################################################
#                                                                   #
#                                                                   #
# 2 COMMON FUNCTIONS (which can be called from the test files)      #
#                                                                   #
#                                                                   #
#####################################################################
#                                                                   #
# NAMING CONVENTION                                                 #
#                                                                   #
# In order to ameliorate the likelihood of naming collisions        #
# and to aid identification, the name of each of the functions      #
# below has been pre-pended with the keyword 'bootstrap__', which,  #
# of course, is a reference to this file.                           #
#                                                                   #
#####################################################################
#####################################################################

#####################################################################
#                                                                   #
# 2.1 CLEAR EXIM QUEUE                                              #
#                                                                   #
#####################################################################
#                                                                   #
# GLOBALS: NONE                                                     #
# ARGS:    NONE                                                     #
# STDOUT:  N/A                                                      #
# EXIT CODE: 0 on success or 1 on failure                           #
#                                                                   #
#####################################################################

function bootstrap__clear_exim_queue() {
  local -i num_queued_messages=0
  local -r function_name="bootstrap__clear_exim_queue"

  num_queued_messages="$(bootstrap__get_num_queued_messages)"

  if [ "${num_queued_messages}" -eq 0 ]; then
    echo "${BOOTSTRAP_SCRIPT_NAME}: ${function_name}: num_queued_messages: 0"
    return 1
  fi

  "$(exim -bp | grep "<" | awk '{ print $3 }' | xargs exim -Mrm)"
}

#####################################################################
#                                                                   #
# 2.2 GENERATE MESSAGE DATA                                         #
#                                                                   #
#####################################################################
#                                                                   #
# Prints the generated message data (when successful)               #
#                                                                   #
#####################################################################
#                                                                   #
#                                                                   #
# ARGS                                                              #
# ----                                                              #
# recipient_email  string  required  The recipient's email          #
# sender_email     string  required  The sender's email             #
# message_subject  string  required  The message subject            #
#                                                                   #
#                                                                   #
# OUTPUT                                                            #
# ------                                                            #
# STDOUT           The generated message data                       #
# EXIT CODE        0 on success. 1, 2 or 3 when unsuccessful.       #
#                                                                   #
#                                                                   #
#####################################################################

function bootstrap__generate_message_data() {
  local -r recipient_email=$1
  local -r sender_email=$2
  local -r message_subject=$3

  if [ -z "${recipient_email}" ]; then
    return 1
  fi

  if [ -z "${sender_email}" ]; then
    return 2
  fi

  if [ -z "${message_subject}" ]; then
    return 3
  fi

  printf "%s" "TO: ${recipient_email}\nFROM: ${sender_email}\nSUBJECT: ${message_subject}\nDATA: ${message_subject}\n."
}

#####################################################################
#                                                                   #
# 2.3 GENERATE MESSAGE ENVELOPE                                     #
#                                                                   #
#####################################################################
#                                                                   #
# Prints the generated message envelope (when successful)           #
#                                                                   #
#####################################################################
#                                                                   #
#                                                                   #
# ARGS                                                              #
# ----                                                              #
# recipient_email  string  required  The recipient's email          #
# recipient_user   string  required  The recipient's username       #
# sender_email     string  required  The sender's email             #
# sender_user      string  required  The sender's username          #
# message_data     string  required  The message data               #
# message_subject  string  required  The message subject            #
#                                                                   #
#                                                                   #
# OUTPUT                                                            #
# ------                                                            #
# STDOUT           The generated message envelope                   #
# EXIT CODE        0 on success. 1 to 6 when unsuccessful.          #
#                                                                   #
#                                                                   #
#####################################################################

function bootstrap__generate_message_envelope() {
  local -r recipient_email=$1
  local -r recipient_user=$2
  local -r sender_email=$3
  local -r sender_user=$4
  local -r message_data=$6
  local -r message_subject=$6

  if [ -z "${recipient_email}" ]; then
    return 1
  fi

  if [ -z "${recipient_user}" ]; then
    return 2
  fi

  if [ -z "${sender_email}" ]; then
    return 3
  fi

  if [ -z "${sender_user}" ]; then
    return 4
  fi

  if [ -z "${message_data}" ]; then
    return 5
  fi

  if [ -z "${message_subject}" ]; then
    return 6
  fi

  printf "%s" "TO: ${recipient_user}<${recipient_email}>\
      \nFROM: ${sender_user}<${sender_email}>\
      \nSUBJECT: ${message_subject}\n${message_data}"
}

#####################################################################
#                                                                   #
# 2.4 GENERATE MESSAGE SUBJECT                                      #
#                                                                   #
#####################################################################
#                                                                   #
# Prints the generated message subject (when successful)            #
#                                                                   #
#####################################################################
#                                                                   #
#                                                                   #
# ARGS                                                              #
# ----                                                              #
# test_name        string  required  The test name                  #
# recipient_email  string  required  The recipient's email          #
# sender_email     string  required  The sender's email             #
# fixture_id       string  optional  The ID of the fixture          #
#                                                                   #
#                                                                   #
# OUTPUT                                                            #
# ------                                                            #
# STDOUT           The generated message subject                    #
# EXIT CODE        0 on success. 1, 2 or 3 when unsuccessful.       #
#                                                                   #
#                                                                   #
#####################################################################

function bootstrap__generate_message_subject() {
  local -r test_name=$1
  local -r recipient_email=$2
  local -r sender_email=$3
  local -r fixture_id="${4:-"0"}"
  local -r message_timestamp=$(date +%s)

  if [ -z "${test_name}" ]; then
    return 1
  fi

  if [ -z "${recipient_email}" ]; then
    return 2
  fi

  if [ -z "${sender_email}" ]; then
    return 3
  fi

  echo "${test_name}_${fixture_id}_${recipient_email}_${sender_email}_${message_timestamp}"
}

#####################################################################
#                                                                   #
# 2.5 GET CERT DIR                                                  #
#                                                                   #
#####################################################################
#                                                                   #
# GLOBALS:   BASH_SOURCE                                            #
# ARGS:      NONE                                                   #
# STDOUT:    The path to the cert dir                               #
# EXIT CODE: 0 on success or 1 on failure                           #
#                                                                   #
#####################################################################

function bootstrap__get_cert_dir() {
  local -r cert_dir="${BOOTSTRAP_SCRIPT_ROOT_DIR}/ca/intermediate"

  if [ ! -d "${cert_dir}" ]; then
    return 1
  fi

  echo "${cert_dir}"
}

#####################################################################
#                                                                   #
# 2.6 GET MAILDIR LATEST EMAIL                                      #
#                                                                   #
#####################################################################
#                                                                   #
# Prints the contents of the latest email (when available)          #
#                                                                   #
#####################################################################
#                                                                   #
#                                                                   #
# GLOBALS                                                           #
# -------                                                           #
# BOOTSTRAP_DOMAIN_MAILDIR string  The default email domain dir     #
#                                                                   #
#                                                                   #
# ARGS                                                              #
# ----                                                              #
# username      string  required  The maildir's owner               #
# maildir_root  string  optional  Defaults _get_maildir_root        #
# domain        string  optional  Defaults to _DOMAIN               #
#                                                                   #
#                                                                   #
# OUTPUT                                                            #
# ------                                                            #
# STDOUT        The contents of the latest email                    #
# EXIT CODE     0 on success or 1 on failure                        #
#                                                                   #
#                                                                   #
#####################################################################

function bootstrap__get_maildir_latest_email() {
  local -r username=$1
  local -r maildir_root="${2:-"$(bootstrap__get_maildir_root)"}"
  local -r domain="${3:-"${BOOTSTRAP_DOMAIN_MAILDIR}"}"

  local latest_email_path=""

  latest_email_path="$(
    bootstrap__get_maildir_latest_email_path \
      "${username}" \
      "${maildir_root}" \
      "${domain}"
  )"

  if [ ! -f "${latest_email_path}" ]; then
    return 1
  fi

  cat "${latest_email_path}"
}

#####################################################################
#                                                                   #
# 2.7 GET MAILDIR LATEST EMAIL PATH                                 #
#                                                                   #
#####################################################################
#                                                                   #
# Prints the path the latest email (when available)                 #
#                                                                   #
#####################################################################
#                                                                   #
#                                                                   #
# GLOBALS                                                           #
# -------                                                           #
# BOOTSTRAP_DOMAIN_MAILDIR          string  Default domain dir      #
# BOOTSTRAP_EMAIL_FILE_NAME_SUFFIX  string  Default suffix          #
#                                                                   #
#                                                                   #
# ARGS                                                              #
# ----                                                              #
# username          required  string  The maildir's owner           #
# maildir_root      optional  string  Defaults _get_maildir_root    #
# domain            optional  string  Defaults to _DOMAIN           #
# file_name_suffix  optional  string  Defaults to _EMAIL_FILE_      #
#                                                                   #
#                                                                   #
# OUTPUT                                                            #
# ------                                                            #
# STDOUT        The path of the latest email                        #
# EXIT CODE     0 on success or 1 on failure                        #
#                                                                   #
#                                                                   #
#####################################################################

function bootstrap__get_maildir_latest_email_path() {
  local -r username=$1
  local -r maildir_root="${2:-"$(bootstrap__get_maildir_root)"}"
  local -r domain="${3:-"${BOOTSTRAP_DOMAIN_MAILDIR}"}"
  local -r file_name_suffix="${4:-"${BOOTSTRAP_EMAIL_FILE_NAME_SUFFIX}"}"

  local maildir_path=""

  maildir_path="$(bootstrap__get_maildir_path "${username}" "${maildir_root}" "${domain}")"

  if [ ! -d "${maildir_path}" ]; then
    return 1
  fi

  find "${maildir_path}" \
    -type f \
    -name "*${file_name_suffix}" \
    -printf "%T@ %p\n" \
    | sort -nr \
    | head -n 1 \
    | cut -d " " -f 2
}

#####################################################################
#                                                                   #
# 2.8 GET MAILDIR PATH                                              #
#                                                                   #
#####################################################################
#                                                                   #
# Prints the path to a maildir                                      #
#                                                                   #
#####################################################################
#                                                                   #
#                                                                   #
# GLOBALS                                                           #
# -------                                                           #
# BOOTSTRAP_DOMAIN_MAILDIR          string  Default domain dir      #
# BOOTSTRAP_MAILDIR_NEW_EMAILS_DIR  string  Default new emails dir  #
#                                                                   #
#                                                                   #
# ARGS                                                              #
# ----                                                              #
# username        string  required  The maildir's owner             #
# maildir_root    string  optional  Defaults _get_maildir_root      #
# domain          string  optional  Defaults _DOMAIN                #
# new_emails_dir  string  optional  Defaults _MAILDIR_NEW_EMAILS_   #
#                                                                   #
#                                                                   #
# OUTPUT                                                            #
# ------                                                            #
# STDOUT          The maildir path                                  #
# EXIT CODE       0 on success. 1 on failure.                       #
#                                                                   #
#                                                                   #
#####################################################################

function bootstrap__get_maildir_path() {
  local -r username=$1
  local -r maildir_root="${2:-"$(bootstrap__get_maildir_root)"}"
  local -r domain="${3:-"${BOOTSTRAP_DOMAIN_MAILDIR}"}"
  local -r new_emails_dir="${4:-"${BOOTSTRAP_MAILDIR_NEW_EMAILS_DIR}"}"

  if [ -z "${username}" ]; then
    return 1
  fi

  echo "${maildir_root}/${domain}/${username}/${new_emails_dir}"
}

#####################################################################
#                                                                   #
# 2.9 GET MAILDIR ROOT                                              #
#                                                                   #
#                                                                   #
# OUTPUT                                                            #
# ------                                                            #
# STDOUT          The maildir root path                             #
# EXIT CODE       0 on success. 1 on failure.                       #
#                                                                   #
#                                                                   #
#####################################################################

function bootstrap__get_maildir_root() {
  echo "/var/mail"

  #local -r maildir_root="$(mariadb < "${BOOTSTRAP_SCRIPT_MAILDIR_ROOT_SQL_PATH}" -N)"
  #sleep 0.3

  #if [ -z "${maildir_root}" ]; then
  #  return 1
  #fi

  #echo "${maildir_root}"
}

#####################################################################
#                                                                   #
# 2.10 GET NUM QUEUED MESSAGES                                      #
#                                                                   #
#####################################################################

function bootstrap__get_num_queued_messages() {
  exim -bp | wc -l
}

#####################################################################
#                                                                   #
# 2.11 GET ROOT DIR                                                 #
#                                                                   #
#####################################################################
#                                                                   #
# GLOBALS:   BOOTSTRAP_SCRIPT_ROOT_DIR                              #
# ARGS:      NONE                                                   #
# STDOUT:    The path to the project root dir                       #
# EXIT CODE: 0                                                      #
#                                                                   #
#####################################################################

function bootstrap__get_root_dir() {
  echo "${BOOTSTRAP_SCRIPT_ROOT_DIR}"
}

#####################################################################
#                                                                   #
# 2.12 REMOVE MAILDIR EMAILS                                        #
#                                                                   #
#####################################################################
#                                                                   #
# Removes emails from maildir by deleting ./new (per username)      #
#                                                                   #
#####################################################################
#                                                                   #
#                                                                   #
# GLOBALS                                                           #
# -------                                                           #
# BOOTSTRAP_DOMAIN_MAILDIR   string  Default domain dir             #
#                                                                   #
#                                                                   #
# ARGS                                                              #
# ----                                                              #
# username        string  required   The maildir's owner            #
# maildir_root    string  optional   Defaults _get_maildir_root     #
# domain          string  optional   Defaults to _DOMAIN            #
#                                                                   #
#                                                                   #
# OUTPUT                                                            #
# ------                                                            #
# STDOUT          NONE                                              #
# EXIT CODE       0 or 1 from rm                                    #
#                                                                   #
#                                                                   #
#####################################################################

function bootstrap__rm_maildir_emails() {
  local -r username=$1
  local -r maildir_root="${2:-"$(bootstrap__get_maildir_root)"}"
  local -r domain="${3:-"${BOOTSTRAP_DOMAIN_MAILDIR}"}"

  local maildir_path=""

  maildir_path="$(bootstrap__get_maildir_path "${username}" "${maildir_root}" "${domain}")"

  if [ ! -d "${maildir_path}" ]; then
    return 1
  fi

  rm -f "${maildir_path}/*"
}

#####################################################################
#                                                                   #
# 2.13 TRIM                                                         #
#                                                                   #
#####################################################################

function bootstrap__trim() {
  local str=$1

  local str_leading_trim=""

  str_leading_trim="$(printf "%s" "${str}" | sed -z 's/^[[:space:]]*//')"

  printf "%s" "${str_leading_trim}" | sed -z 's/[[:space:]]*$//'
}
