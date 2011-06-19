#!/bin/bash
#
# Copyright (c) 2010 Linagora
# Patrick Guiran <pguiran@linagora.com>
# http://github.com/Tauop/ScriptHelper
#
# ScriptHelper is free software, you can redistribute it and/or modify
# it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# ScriptHelper is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# Load library ---------------------------------------------------------------
SCRIPT_HELPER_DIRECTORY='..'
[ -r /etc/ScriptHelper.conf ] && . /etc/ScriptHelper.conf

testcases=$( find "${SCRIPT_HELPER_DIRECTORY}/tests/" -type f -iname "*.testcase" -printf "%P\n" \
             | sed -e 's/^\(.*\)[.]testcase$/\1/' )

usage () {
  testcases=$( echo -n "${testcases}" | tr $'\n' ',' | sed -e 's/,/, /g' )
  echo "Usage: $0 <test-case>"
  echo "    <test-case> : ${testcases}" | fold -s
  exit 1
}

if [ $# -ne 1 ]; then
 echo 'ERROR: Bad arguments'
  usage
fi

TEST_CASE="$1"
TEST_CASE_DIR="${SCRIPT_HELPER_DIRECTORY}/tests"

# don't use function.lib.sh functions !
mDOTHIS() { echo -n "- $* ... "; }
mOK()     { echo 'OK';           }
mKO()     { echo 'KO';           }

if [ "${TEST_CASE}" != 'all' ]; then
  TEST_CASE="${TEST_CASE_DIR}/${TEST_CASE}.testcase"
  if [ ! -r "${TEST_CASE}" ]; then
    echo 'ERROR: unknown test-case'
    usage
  fi
  mDOTHIS "Launch $1"
  # Load the test-case
  if [ "${test}" = "ask" ]; then
    ( . "${TEST_CASE}" ) && mOK || mKO
  else
    ( . "${TEST_CASE}" >/dev/null ) && mOK || mKO
  fi
else
  for test in ${testcases}; do
    mDOTHIS "Launch ${test}"
    TEST_CASE="${TEST_CASE_DIR}/${test}.testcase"
    if [ "${test}" = "ask" ]; then
      ( . "${TEST_CASE}" ) && mOK || ( mKO; break )
    else
      ( . "${TEST_CASE}" >/dev/null ) && mOK || ( mKO; break )
    fi
  done
fi

echo
echo "*** All tests done ***"
echo
