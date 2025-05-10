#!/usr/bin/env bash

set -euo pipefail

#####################################################################
#                                                                   #
# Script:  send_remote_positive.test.sh                             #
#                                                                   #
# Purpose: A set of positive SMTP remote mail tests                 #
#                                                                   #
# Date:    14th February 2025 (revised)                             #
#                                                                   #
# Author:  J.A.Strachan                                             #
#                                                                   #
#####################################################################


#####################################################################
#                                                                   #
# CORE SECTIONS (within the code below)                             #
#                                                                   #
#                                                                   #
# 1 TEST DEFINITION                                                 #
#                                                                   #
# 1.1 DATA PROVIDER ARGS                                            #
# 1.2 CONSTANTS                                                     #
# 1.3 WORKING VARS                                                  #
# 1.4 REMOVE EXISTING EMAILS                                        #
# 1.5 GENERATE MSG                                                  #
# 1.6 SEND MSG                                                      #
# 1.7 GET THE EXIT CODE                                             #
# 1.8 ASSERTIONS                                                    #
#                                                                   #
#                                                                   #
# 2 TEST FIXTURE DEFINITIONS                                        #
#                                                                   #
#####################################################################


#####################################################################
#                                                                   #
# 1 TEST DEFINITION (with the data_provider reference below)        #
#                                                                   #
#####################################################################

# data_provider test_send_remote_positive_fixtures
function test_send_remote_positive() {


  ###################################################################
  #                                                                 #
  # 1.1 DATA PROVIDER ARGS                                          #
  #                                                                 #
  ###################################################################

  local -i -r fixture_id="$(($1))"
  local    -r recipient_email=$2
  local    -r recipient_user=$3
  local    -r sender_email=$4
  local    -r sender_user=$5
  local -r -r exit_code_expected="$(($6))"

  
  ###################################################################
  #                                                                 #
  # 1.2 CONSTANTS                                                   #
  #                                                                 #
  ###################################################################

  local    -r test_name="send_remote_positive"

  
  ###################################################################
  #                                                                 #
  # 1.3 WORKING VARS                                                #
  #                                                                 #
  ###################################################################

  local -i    exit_code_found=1
  local       message_data=""
  local       message_envelope=""
  local       message_subject=""

  
  ###################################################################
  #                                                                 #
	# 1.4 REMOVE EXISTING EMAILS (FOR SENDER)                         #
  #                                                                 #
  ###################################################################

  bootstrap__rm_maildir_emails "${sender_user}"
    
  
  ###################################################################
  #                                                                 #
  # 1.5 GENERATE MSG                                                #
  #                                                                 #
  ###################################################################
  
  message_subject=$(                     \
    bootstrap__generate_message_subject  \
      "${test_name}"                     \
      "${recipient_email}"               \
      "${sender_email}"                  \
      "${fixture_id}"                    \
  )

  message_data=$(                        \
    bootstrap__generate_message_data     \
      "${recipient_email}"               \
      "${sender_email}"                  \
      "${message_subject}"               \
  )

  message_envelope=$(                    \
    bootstrap__generate_message_envelope \
      "${recipient_email}"               \
      "${recipient_user}"                \
      "${sender_email}"                  \
      "${sender_user}"                   \
      "${message_data}"                  \
      "${message_subject}"               \
  )
  
  ###################################################################
  #                                                                 #
  # 1.6 SEND MSG                                                    #
  #                                                                 #
  ###################################################################
  
	echo -e "${message_envelope}" | exim4 -t

  
  ###################################################################
  #                                                                 #
  # 1.7 GET THE EXIT CODE                                           #
  #                                                                 #
  ###################################################################
  
    exit_code_found=$?
    sleep 0.3
    
    email_path="$(                               \
      bootstrap__get_maildir_latest_email_path   \
        "${sender_user}"                         \
    )"


  ###################################################################
  #                                                                 #
  # 1.8 ASSERTIONS                                                  #
  #                                                                 #
  ###################################################################
  
    assert_empty     "${email_path}"
    assert_not_empty "${message_subject}"
    assert_same      "${exit_code_expected}" "${exit_code_found}"
}


#####################################################################
#                                                                   #
# 2 TEST FIXTURE DEFINITIONS                                        #
#                                                                   #
#####################################################################

function test_send_remote_positive_fixtures() {

  #
  # [ id, recipient_email, recipient_user, sender_email, sender_user, exit_code_expected ]
  #
  echo 0                                               \
       "${BOOTSTRAP_EMAIL_REMOTE}"                     \
       "${BOOTSTRAP_USER_TEST_ALIAS_ONE}"              \
       "${BOOTSTRAP_USER_TEST}"                        \
       "${BOOTSTRAP_USER_TEST}"                        \
       0
  
	echo 1                                               \
       "${BOOTSTRAP_EMAIL_REMOTE}"                     \
       "${BOOTSTRAP_USER_TEST_ALIAS_ONE}"              \
       "${BOOTSTRAP_EMAIL_TEST_LOCAL}"                 \
       "${BOOTSTRAP_USER_TEST}"                        \
       0
  
	echo 2                                               \
       "${BOOTSTRAP_EMAIL_REMOTE}"                     \
       "${BOOTSTRAP_USER_TEST_ALIAS_ONE}"              \
       "${BOOTSTRAP_EMAIL_TEST_DOMAIN}"                \
       "${BOOTSTRAP_USER_TEST}"                        \
       0

	echo 3                                               \
       "${BOOTSTRAP_EMAIL_REMOTE}"                     \
       "${BOOTSTRAP_USER_TEST_ALIAS_ONE}"              \
       "${BOOTSTRAP_USER_TEST}"                        \
       "${BOOTSTRAP_USER_TEST_ALIAS_ONE}"              \
       0

	echo 4                                               \
       "${BOOTSTRAP_EMAIL_REMOTE}"                     \
       "${BOOTSTRAP_USER_TEST_ALIAS_ONE}"              \
       "${BOOTSTRAP_EMAIL_TEST_LOCAL}"                 \
       "${BOOTSTRAP_USER_TEST_ALIAS_ONE}"              \
       0

	echo 5                                               \
       "${BOOTSTRAP_EMAIL_REMOTE}"                     \
       "${BOOTSTRAP_USER_TEST_ALIAS_ONE}"              \
       "${BOOTSTRAP_EMAIL_TEST_DOMAIN}"                \
       "${BOOTSTRAP_USER_TEST_ALIAS_ONE}"              \
       0
}
