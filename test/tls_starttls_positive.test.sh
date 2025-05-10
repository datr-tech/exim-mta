#!/usr/bin/env bash

set -euo pipefail

#####################################################################
#                                                                   #
# Script:  tls_starttls_positive.test.sh                            #
#                                                                   #
# Purpose: A set of positive TLS tests using ports 25 and 587       #
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
# 1.4 REMOVE EXISTING EMAILS PER RECIPIENT                          #
# 1.5 GENERATE MSG                                                  #
# 1.6 SEND MSG                                                      #
# 1.7 GET THE EXIT CODE AND THE CONTENTS OF THE DELIVERED MSG       #
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

# data_provider test_tls_starttls_positive_fixtures
function test_tls_starttls_positive() {


  ###################################################################
  #                                                                 #
  # 1.1 DATA PROVIDER ARGS                                          #
  #                                                                 #
  ###################################################################

  local -i -r fixture_id="$(($1))"
  local    -r recipient_email=$2
  local    -r recipient_user=$3
  local    -r sender_email=$4
  local    -r tls_version=$5
  local -i -r port="$(($6))"
  local -r -r exit_code_expected="$(($7))"

  
  ###################################################################
  #                                                                 #
  # 1.2 CONSTANTS                                                   #
  #                                                                 #
  ###################################################################

  local    -r cert_dir="$(bootstrap__get_cert_dir)"
  local    -r test_name="tls_starttls_positive"

  
  ###################################################################
  #                                                                 #
  # 1.3 WORKING VARS                                                #
  #                                                                 #
  ###################################################################

  local       email_contents=""
  local       email_path=""
  local -i    exit_code_found=-1
  local       message_data=""
  local       message_subject=""

  
  ###################################################################
  #                                                                 #
  # 1.4 REMOVE EXISTING EMAILS PER RECIPIENT                        #
  #                                                                 #
  ###################################################################

  bootstrap__rm_maildir_emails "${recipient_user}"
    
  
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

  
  ###################################################################
  #                                                                 #
  # 1.6 SEND MSG                                                    #
  #                                                                 #
  ###################################################################
  
  swaks                                                           \
    --to              "${recipient_email}"                        \
    --from            "${sender_email}"                           \
    --server          "${BOOTSTRAP_DOMAIN_LOCAL}"                 \
    --port            "${port}"                                   \
    --data            "${message_data}"                           \
    --tls-cert        "${cert_dir}/certs/user.cert.pem"           \
    --tls-key         "${cert_dir}/private/user.key.pem"          \
    --tls-protocol    "${tls_version}"                            \
    -tls                                                          \
  > /dev/null 2>&1

  
  ###################################################################
  #                                                                 #
  # 1.7 GET THE EXIT CODE AND THE CONTENTS OF THE DELIVERED MSG     #
  #                                                                 #
  ###################################################################
  
    exit_code_found=$?
    sleep 0.3
    
    email_contents="$(                           \
      bootstrap__get_maildir_latest_email        \
        "${recipient_user}"                      \
    )"

    email_path="$(                               \
      bootstrap__get_maildir_latest_email_path   \
        "${recipient_user}"                      \
    )"


  ###################################################################
  #                                                                 #
  # 1.8 ASSERTIONS                                                  #
  #                                                                 #
  ###################################################################
  
    assert_is_file   "${email_path}"
    assert_not_empty "${email_contents}"
    assert_not_empty "${message_subject}"
    assert_contains  "${message_subject}"    "${email_contents}"
    assert_same      "${exit_code_expected}" "${exit_code_found}"
}


#####################################################################
#                                                                   #
# 2 TEST FIXTURE DEFINITIONS                                        #
#                                                                   #
#####################################################################

function test_tls_starttls_positive_fixtures() {

  #
  # [ id, recipient_email, recipient_user, sender_email, tls_version, port, exit_code_expected ]
  #
  echo 0                                               \
       "${BOOTSTRAP_EMAIL_TEST_LOCAL_ALIAS_1}"         \
       "${BOOTSTRAP_USER_TEST}"                        \
       "${BOOTSTRAP_EMAIL_ADMIN_LOCAL}"                \
       "${BOOTSTRAP_TLS_1_2}"                          \
       "${BOOTSTRAP_EXIM_UNSECURE_PORT}"               \
       0

  echo 1                                               \
       "${BOOTSTRAP_EMAIL_TEST_DOMAIN_ALIAS_1}"        \
       "${BOOTSTRAP_USER_TEST}"                        \
       "${BOOTSTRAP_EMAIL_ADMIN_LOCAL}"                \
       "${BOOTSTRAP_TLS_1_2}"                          \
       "${BOOTSTRAP_EXIM_UNSECURE_PORT}"               \
       0
  
  echo 2                                               \
       "${BOOTSTRAP_EMAIL_TEST_LOCAL_ALIAS_1}"         \
       "${BOOTSTRAP_USER_TEST}"                        \
       "${BOOTSTRAP_EMAIL_REMOTE}"                     \
       "${BOOTSTRAP_TLS_1_2}"                          \
       "${BOOTSTRAP_EXIM_UNSECURE_PORT}"               \
       0
  
  echo 3                                               \
       "${BOOTSTRAP_EMAIL_TEST_DOMAIN_ALIAS_1}"        \
       "${BOOTSTRAP_USER_TEST}"                        \
       "${BOOTSTRAP_EMAIL_REMOTE}"                     \
       "${BOOTSTRAP_TLS_1_2}"                          \
       "${BOOTSTRAP_EXIM_UNSECURE_PORT}"               \
       0
  
  echo 4                                               \
       "${BOOTSTRAP_EMAIL_TEST_LOCAL_ALIAS_1}"         \
       "${BOOTSTRAP_USER_TEST}"                        \
       "${BOOTSTRAP_EMAIL_ADMIN_LOCAL}"                \
       "${BOOTSTRAP_TLS_1_3}"                          \
       "${BOOTSTRAP_EXIM_UNSECURE_PORT}"               \
       0
  
  echo 5                                               \
       "${BOOTSTRAP_EMAIL_TEST_DOMAIN_ALIAS_1}"        \
       "${BOOTSTRAP_USER_TEST}"                        \
       "${BOOTSTRAP_EMAIL_ADMIN_LOCAL}"                \
       "${BOOTSTRAP_TLS_1_3}"                          \
       "${BOOTSTRAP_EXIM_UNSECURE_PORT}"               \
       0
  
  echo 6                                               \
       "${BOOTSTRAP_EMAIL_TEST_LOCAL_ALIAS_1}"         \
       "${BOOTSTRAP_USER_TEST}"                        \
       "${BOOTSTRAP_EMAIL_REMOTE}"                     \
       "${BOOTSTRAP_TLS_1_3}"                          \
       "${BOOTSTRAP_EXIM_UNSECURE_PORT}"               \
       0
  
  echo 7                                               \
       "${BOOTSTRAP_EMAIL_TEST_DOMAIN_ALIAS_1}"        \
       "${BOOTSTRAP_USER_TEST}"                        \
       "${BOOTSTRAP_EMAIL_REMOTE}"                     \
       "${BOOTSTRAP_TLS_1_3}"                          \
       "${BOOTSTRAP_EXIM_UNSECURE_PORT}"               \
       0
  
  echo 8                                               \
       "${BOOTSTRAP_EMAIL_TEST_LOCAL_ALIAS_1}"         \
       "${BOOTSTRAP_USER_TEST}"                        \
       "${BOOTSTRAP_EMAIL_ADMIN_LOCAL}"                \
       "${BOOTSTRAP_TLS_1_2}"                          \
       "${BOOTSTRAP_EXIM_SECURE_PORT}"                 \
       0
  
  echo 9                                               \
       "${BOOTSTRAP_EMAIL_TEST_DOMAIN_ALIAS_1}"        \
       "${BOOTSTRAP_USER_TEST}"                        \
       "${BOOTSTRAP_EMAIL_ADMIN_LOCAL}"                \
       "${BOOTSTRAP_TLS_1_2}"                          \
       "${BOOTSTRAP_EXIM_SECURE_PORT}"                 \
       0
  
  echo 10                                              \
       "${BOOTSTRAP_EMAIL_TEST_LOCAL_ALIAS_1}"         \
       "${BOOTSTRAP_USER_TEST}"                        \
       "${BOOTSTRAP_EMAIL_REMOTE}"                     \
       "${BOOTSTRAP_TLS_1_2}"                          \
       "${BOOTSTRAP_EXIM_SECURE_PORT}"                 \
       0
  
  echo 11                                              \
       "${BOOTSTRAP_EMAIL_TEST_DOMAIN_ALIAS_1}"        \
       "${BOOTSTRAP_USER_TEST}"                        \
       "${BOOTSTRAP_EMAIL_REMOTE}"                     \
       "${BOOTSTRAP_TLS_1_2}"                          \
       "${BOOTSTRAP_EXIM_SECURE_PORT}"                 \
       0
  
  echo 12                                              \
       "${BOOTSTRAP_EMAIL_TEST_LOCAL_ALIAS_1}"         \
       "${BOOTSTRAP_USER_TEST}"                        \
       "${BOOTSTRAP_EMAIL_ADMIN_LOCAL}"                \
       "${BOOTSTRAP_TLS_1_3}"                          \
       "${BOOTSTRAP_EXIM_SECURE_PORT}"                 \
       0
  
  echo 13                                              \
       "${BOOTSTRAP_EMAIL_TEST_DOMAIN_ALIAS_1}"        \
       "${BOOTSTRAP_USER_TEST}"                        \
       "${BOOTSTRAP_EMAIL_ADMIN_LOCAL}"                \
       "${BOOTSTRAP_TLS_1_3}"                          \
       "${BOOTSTRAP_EXIM_SECURE_PORT}"                 \
       0
  
  echo 14                                              \
       "${BOOTSTRAP_EMAIL_TEST_LOCAL_ALIAS_1}"         \
       "${BOOTSTRAP_USER_TEST}"                        \
       "${BOOTSTRAP_EMAIL_REMOTE}"                     \
       "${BOOTSTRAP_TLS_1_3}"                          \
       "${BOOTSTRAP_EXIM_SECURE_PORT}"                 \
       0
  
  echo 15                                              \
       "${BOOTSTRAP_EMAIL_TEST_DOMAIN_ALIAS_1}"        \
       "${BOOTSTRAP_USER_TEST}"                        \
       "${BOOTSTRAP_EMAIL_REMOTE}"                     \
       "${BOOTSTRAP_TLS_1_3}"                          \
       "${BOOTSTRAP_EXIM_SECURE_PORT}"                 \
       0
}
