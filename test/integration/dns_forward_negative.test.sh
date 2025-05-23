#!/usr/bin/env bash

set -euo pipefail

#
# Common vars
#
declare -i DNS_NUM_RETRIES=1
declare -i DNS_PORT=53
declare -i DNS_TIMEOUT_SECONDS=1
declare DELIM=";"

#
# Fixtures: [ requested_domain, requested_record_type, result_should_contain ]
#
declare -a fixtures=(
  "phone.strachan.email ${DELIM} a   ${DELIM} NXDOMAIN"
  "phone.strachan.email ${DELIM} mx  ${DELIM} NXDOMAIN"
  "phone.strachan.email ${DELIM} ns  ${DELIM} NXDOMAIN"
  "phone.strachan.email ${DELIM} soa ${DELIM} NXDOMAIN"
  "web.strachan.email   ${DELIM} a   ${DELIM} NXDOMAIN"
  "web.strachan.email   ${DELIM} mx  ${DELIM} NXDOMAIN"
  "web.strachan.email   ${DELIM} ns  ${DELIM} NXDOMAIN"
  "web.strachan.email   ${DELIM} soa ${DELIM} NXDOMAIN"
)

function test_dns_forward_positive() {
  #
  # Fixture vars
  #
  declare fixture
  declare -a fixture_array

  #
  # Per fixture vars
  #
  declare requested_domain
  declare requested_record_type
  declare result_should_contain

  #
  # Trimmed per fixture vars
  #
  declare requested_domain_bootstrap__trimmed
  declare requested_record_type_bootstrap__trimmed
  declare result_should_contain_bootstrap__trimmed

  #
  # Result count var
  #
  declare -i result_should_contain_count=0

  #
  # Loop through the fixtures and
  # perform a test per fixture
  #
  for fixture in "${fixtures[@]}"; do
    #
    # ARRANGE 1
    #
    # Split fixture into fixture_array by DELIM
    #
    IFS="${DELIM}" read -r -a fixture_array <<< "${fixture}"

    #
    # ARRANGE 2
    #
    # Extract the 'requested_*' and the
    # 'result_*' values from fixture_array
    #
    requested_domain="${fixture_array[0]}"
    requested_record_type="${fixture_array[1]}"
    result_should_contain="${fixture_array[2]}"

    #
    # ARRANGE 3
    #
    # Trim the extracted 'requested_*'
    # and the 'result_*' values
    #
    requested_domain_bootstrap__trimmed="$(bootstrap__trim "${requested_domain}")"
    requested_record_type_bootstrap__trimmed="$(bootstrap__trim "${requested_record_type}")"
    result_should_contain_bootstrap__trimmed="$(bootstrap__trim "${result_should_contain}")"

    #
    # ACT
    #
    # Does the local nslookup call for
    # 'requested_record_type' return a set
    # of values with 'result_should_contain'?
    #
    result_should_contain_count="$(
      nslookup \
        -port="${DNS_PORT}" \
        -retry="${DNS_NUM_RETRIES}" \
        -timeout="${DNS_TIMEOUT_SECONDS}" \
        -type="${requested_record_type_bootstrap__trimmed}" \
        "${requested_domain_bootstrap__trimmed}" \
        | grep -c "${result_should_contain_bootstrap__trimmed}"
    )"

    #
    # ASSERT
    #
    assert_greater_than 0 "${result_should_contain_count}"

    #
    # TEARDOWN PER FIXTURE
    #
    requested_domain=""
    requested_record_type=""
    result_should_contain=""

    requested_domain_bootstrap__trimmed=""
    requested_record_type_bootstrap__trimmed=""
    result_should_contain_bootstrap__trimmed=""

    result_should_contain_count=0
  done
}
