#!/usr/bin/env bash

set -euo pipefail

#
# fixtures: [rcpt_email; rcpt_user; sender_email; sender_user]
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
  # Fixture vars
  #
  declare fixture
  declare -a fixture_array

  #
  # Mailbox vars
  #
  declare mailbox_admin
  mailbox_admin="$(get_mailbox_path "admin")"
  declare mailbox_user

  #
  # Message vars
  #
  declare envelope
  declare message

  #
  # Queue vars
  #
  declare -i -r num_queued_expected=0
  declare -i num_queued_found=1

  #
  # RCPT / SENDER user vars
  #
  declare rcpt_email
  declare rcpt_user
  declare sender_email
  declare sender_user

  #
  # Clear the exim queue
  #
  clear_exim_queue

  for fixture in "${fixtures[@]}";
  do
    #
    # ARRANGE 1
    #
    # Split 'fixture' into 'fixture_array'
    #
    IFS='; ' read -r -a fixture_array <<< "${fixture}"

    rcpt_email="${fixture_array[0]}"
    rcpt_user="${fixture_array[1]}"
    sender_email="${fixture_array[2]}"
    sender_user="${fixture_array[3]}"

    message="MESSAGE: test_send_local_negative"
    envelope="TO: ${rcpt_user}<${rcpt_email}> \
      \nFROM: ${sender_user}<${sender_email}> \
      \nSUBJECT: TEST \
      \n${message}"

    rm_mailbox "${rcpt_user}"
    rm_mailbox "admin"

    #
    # ACT
    #
    echo -e "${envelope}" | exim -t
    sleep 0.3
    num_queued_found="$(get_num_queued_messages)"
    mailbox_user="$(get_mailbox_path "${rcpt_user}")"

    #
    # ASSERT
    #
    assert_same "${num_queued_expected}" "${num_queued_found}"
    assert_file_exists "${mailbox_admin}"
    assert_not_empty "$(cat "${mailbox_admin}")"
    assert_file_not_exists "${mailbox_user}"

    #
    # TEARDOWN (per fixture)
    #
    clear_exim_queue
    envelope=""
    mailbox_user=""
    message=""
    num_queued_found=1
    rcpt_email=""
    rcpt_user=""
    sender_email=""
    sender_user=""
  done
}
