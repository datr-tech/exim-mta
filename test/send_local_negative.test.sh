#!/usr/bin/env bash

set -euo pipefail

#
# fixtures: [recipient_email; recipient_user; sender_email; sender_user]
#
declare -a fixtures=(
  "admin1; admin1; joealdersonstrachan; joealdersonstrachan"
  "admin1@localhost; admin1; joealdersonstrachan@localhost; joealdersonstrachan"
  "admin1@strachan.email; admin1; joealdersonstrachan@strachan.email; joealdersonstrachan"
  "hostmaster2; hostmaster2; joealdersonstrachan; joealdersonstrachan"
  "hostmaster2; hostmaster2; joealdersonstrachan@localhost; joealdersonstrachan"
  "hostmaster2; hostmaster2; joealdersonstrachan@strachan.email; joealdersonstrachan"
  "joestrachan1; joealdersonstrachan1; admin@localhost; admin"
  "joestrachan1@localhost; joealdersonstrachan1; admin@localhost; admin"
  "joestrachan1@strachan.email; joealdersonstrachan1; admin@localhost; admin"
)

function test_send_local_negative() {
  #
  # Email vars
  #
  declare email_path

  #
  # Fixture vars
  #
  declare fixture
  declare -a fixture_array
  declare -i i

  #
  # Message vars
  #
  declare message_data
  declare message_envelope
  declare message_timestamp

  #
  # Queue vars
  #
  declare -i -r num_queued_expected=0
  declare -i num_queued_found=-1

  #
  # RCPT / SENDER user vars
  #
  declare recipient_email
  declare recipient_user
  declare sender_email
  declare sender_user

  #
  # Clear the exim queue
  #
  bootstrap__clear_exim_queue

  for i in "${!fixtures[@]}"; do
    #
    # ARRANGE 1
    #
    # Split 'fixture' into 'fixture_array'
    #
    fixture="${fixtures[$i]}"
    IFS='; ' read -r -a fixture_array <<< "${fixture}"

    recipient_email="${fixture_array[0]}"
    recipient_user="${fixture_array[1]}"
    sender_email="${fixture_array[2]}"
    sender_user="${fixture_array[3]}"

    bootstrap__rm_maildir_emails "${recipient_user}"

    message_timestamp=$(date +%s)
    message_data="test_send_local_positive_${i}_${recipient_email}_${sender_email}_${message_timestamp}"
    message_envelope="TO: ${recipient_user}<${recipient_email}> \
      \nFROM: ${sender_user}<${sender_email}> \
      \nSUBJECT: TEST \
      \n${message_data}"

    #
    # ACT
    #
    echo -e "${message_envelope}" | exim -t
    sleep 0.3

    num_queued_found="$(bootstrap__get_num_queued_messages)"
    email_path="$(bootstrap__get_maildir_latest_email_path "${recipient_user}")"

    #
    # ASSERT
    #
    assert_same "${num_queued_expected}" "${num_queued_found}"
    assert_file_not_exists "${email_path}"

    #
    # TEARDOWN (per fixture)
    #
    bootstrap__clear_exim_queue

    email_path=""
    message_data=""
    message_envelope=""
    message_timestamp=""
    num_queued_found=-1
    recipient_email=""
    recipient_user=""
    sender_email=""
    sender_user=""
  done
}
