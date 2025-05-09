#!/usr/bin/env bash

set -euo pipefail

#
# Permissions
#
if [[ $EUID -ne 0 ]]; then
  echo "use: sudo make test"
  exit 1
fi

#
# Constants
#
declare -r MAILBOX_ROOT="/var/mail"

#
# Required dependencies
#
declare required_dependency
declare -a required_dependencies=(
  "awk"
 # "bind"
 # "dovecot"
  "echo"
  #"exim"
  "expect"
  "grep"
  "nslookup"
  "sed"
  "wc"
  "xargs"
)

#
# Required dependencies
#
for required_dependency in "${required_dependencies[@]}"
do
  if ! command -v "${required_dependency}" > /dev/null 2>&1; then
    echo "${required_dependency}: not found"
    exit 1
  fi
done

#
# Helper: clear the exim queue
#
function clear_exim_queue() {
  num_queued_messages="$(get_num_queued_messages)"

  if [ "${num_queued_messages}" -eq 0 ]; then
    return 1
  fi

  "$(exim -bp | grep "<" | awk '{ print $3 }' | xargs exim -Mrm)"
}

#
# Helper: get mailbox path
#
function get_mailbox_path() {
  local username=$1
  local mailbox_root="${2:-"${MAILBOX_ROOT}"}"

  echo "${mailbox_root}/${username}"
}

#
# Helper: get the total number of queued messages
#
function get_num_queued_messages() {
  exim -bp | wc -l
}

#
# Helper: has mailbox path
#
function has_mailbox_path() {
  local mailbox_path=$1

  if [ ! -f "${mailbox_path}" ]; then
    return 1
  fi
}

#
# Helper: rm a mailbox by username
#
function rm_mailbox() {
  local username=$1
  local mailbox_path

  mailbox_path="$(get_mailbox_path "${username}")"

  if ! has_mailbox_path "${mailbox_path}"; then
    return 1
  fi

  rm -f "${mailbox_path}"
}

#
# Helper: trim leading and trailing whitespace
#
function trim() {
  local str=$1
  local str_leading_trim

  str_leading_trim="$(printf "%s" "${str}" | sed -z 's/^[[:space:]]*//')"
  printf "%s" "${str_leading_trim}" | sed -z 's/[[:space:]]*$//'
}
