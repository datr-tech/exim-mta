#!/usr/bin/env bash

set -euo pipefail

#
# Common vars
#
declare DNS_IP="127.0.0.1"
declare -i DNS_NUM_RETRIES=1
declare -i DNS_PORT=53
declare -i DNS_TIMEOUT_SECONDS=1
declare DELIM=";"

#
# fixtures: [ ip_to_lookup, domain_expected ]
#
declare -a fixtures=(
  "192.168.1.123 ${DELIM} phone.strachan.email"
  "192.168.1.118 ${DELIM} web.strachan.email"
)

function test_dns_reverse_positive() {

  #
  # Fixture vars
  #
  declare fixture
  declare -a fixture_array

  #
  # Per fixture vars
  #
  declare ip_to_lookup
  declare domain_expected

  #
  # Trimmed per fixture vars
  #
  declare ip_to_lookup_bootstrap__trimmed
  declare domain_expected_bootstrap__trimmed

  #
  # Count var
  #
  declare -i domain_expected_count=0

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
    # Extract the required values by
    # position from fixture_array
    #
    ip_to_lookup="${fixture_array[0]}"
    domain_expected="${fixture_array[1]}"

    #
    # ARRANGE 3
    #
    # Trim the extracted values
    #
    ip_to_lookup_bootstrap__trimmed="$(bootstrap__trim "${ip_to_lookup}")"
    domain_expected_bootstrap__trimmed="$(bootstrap__trim "${domain_expected}")"

    #
    # ACT
    #
    # Does the local nslookup call for
    # 'ip_to_lookup' return the expected
    # domain?
    #
    domain_expected_count="$(
      nslookup \
        -port="${DNS_PORT}" \
        -retry="${DNS_NUM_RETRIES}" \
        -timeout="${DNS_TIMEOUT_SECONDS}" \
        "${ip_to_lookup_bootstrap__trimmed}" \
        "${DNS_IP}" \
        | grep -c "${domain_expected_bootstrap__trimmed}"
    )"

    #
    # ASSERT
    #
    assert_greater_than 0 "${domain_expected_count}"

    #
    # TEARDOWN PER FIXTURE
    #
    ip_to_lookup=""
    domain_expected=""

    ip_to_lookup_bootstrap__trimmed=""
    domain_expected_bootstrap__trimmed=""

    domain_expected_count=0
  done
}
