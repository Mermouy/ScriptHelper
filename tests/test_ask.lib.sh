#!/bin/bash
#
# Copyright (c) 2010 Linagora
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
if [ -r ../functions.lib.sh ]; then
  source ../functions.lib.sh
else
  echo "[ERROR] Unable to load function.lib.sh"
  exit 1
fi

SOURCE ../ask.lib.sh

TEST_FILE="/tmp/test.${RANDOM}"
SET_LOG_FILE "${TEST_FILE}"

TEST_ANSWER_FILE="/tmp/test_answer.${RANDOM}"
ASK_SET_ANSWER_LOG_FILE "${TEST_ANSWER_FILE}"

# Utility functions ----------------------------------------------------------

TEST_FAILED() {
  rm -f "${TEST_FILE}" "${TEST_ANSWER_FILE}"
  echo '[ERROR] Test failed'
  exit 1
}

check_TEST_FILE() {
  content=`cat ${TEST_FILE}`
  [ "${content}" != "$*" ] && TEST_FAILED
}

check_LOG_FILE() {
  local content=
  if [ -n "${__OUTPUT_LOG_FILE__}" ]; then
    # delete the date, at the beginning of each line
    content=`cat "${__OUTPUT_LOG_FILE__}" | cut -d ']' -f2- | sed -e 's/^ //' | tr $'\n' ':'`
    content2=`echo "$*" | tr $'\n' ':'`
    [ "${content}" != "${content2}" ] && TEST_FAILED
    reset_FILES
  fi
}

reset_FILES() {
  echo -n '' > "${TEST_FILE}"
  [ -f "${__OUTPUT_LOG_FILE__}" ] && echo -n '' > "${__OUTPUT_LOG_FILE__}"
  [ -f "${__ERROR_LOG_FILE__}"  ] && echo -n '' > "${__ERROR_LOG_FILE__}"
}


# Make tests -----------------------------------------------------------------

msg_opt=
loop_count=0

while [ "$loop_count" != "2" ]; do

  MESSAGE ${msg_opt} --no-log "** * Test: HIT_TO_CONTINUE() * **"
  HIT_TO_CONTINUE
  check_LOG_FILE "User press ENTER to continue"


  result=
  MESSAGE ${msg_opt} --no-log "** * Test: ASK anything * **"
  ASK     ${msg_opt} result "Type anything:"
  MESSAGE ${msg_opt} --no-log "You have type \"${result}\""
  MESSAGE ${msg_opt} --no-log ''

  check_LOG_FILE "Type anything: => ${result}"


  result=
  MESSAGE ${msg_opt} --no-log "** * Test: ASK yes/no * **"
  ASK     ${msg_opt} --yesno result "yes or no ?"
  MESSAGE ${msg_opt} --no-log "You have type \"${result}\""
  MESSAGE ${msg_opt} --no-log ''

  check_LOG_FILE "yes or no ? => ${result}"
  [ "${result}" != "Y" -a "${result}" != "N" ] && TEST_FAILED


  result=
  MESSAGE ${msg_opt} --no-log "** * Test: ASK yes/no with Yes in default * **"
  ASK     ${msg_opt} --yesno result "yes/no [Y] ?" 'Y'
  MESSAGE ${msg_opt} --no-log "You have type \"${result}\""
  MESSAGE ${msg_opt} --no-log ''

  check_LOG_FILE "yes/no [Y] ? => ${result}"
  [ "${result}" != "Y" -a "${result}" != "N" ] && TEST_FAILED


  result=
  MESSAGE ${msg_opt} --no-log "** * Test: ASK number * **"
  MESSAGE ${msg_opt} --no-log "  Enter a bad response to see the error message \"Your answer is not a number\""
  ASK     ${msg_opt} --number result "Number:" '' 'Your answer is not a number'
  MESSAGE ${msg_opt} --no-log "You have type \"${result}\""
  MESSAGE ${msg_opt} --no-log ''

  check_LOG_FILE "Number: => ${result}"
  echo "${answer}" | grep '^[0-9]*$' >/dev/null 2>/dev/null
  [ $? -ne 0 ] && TEST_FAILED


  result=
  MESSAGE ${msg_opt} --no-log "** * Test: ASK number with 9 in default * **"
  ASK     ${msg_opt} --number result "Number [9]:" '9'
  MESSAGE ${msg_opt} --no-log "You have type \"${result}\""
  MESSAGE ${msg_opt} --no-log ''

  check_LOG_FILE "Number [9]: => ${result}"
  echo "${answer}" | grep '^[0-9]*$' >/dev/null 2>/dev/null
  [ $? -ne 0 ] && TEST_FAILED


  result=
  MESSAGE ${msg_opt} --no-log "** * Test: ASK --no-print ** *"
  ASK     ${msg_opt} --pass result "Password:"
  MESSAGE ${msg_opt} --no-log "You have type \"${result}\""
  MESSAGE ${msg_opt} --no-log ''

  check_LOG_FILE "Password: => ${result//?/#}"


  result=
  MESSAGE ${msg_opt} --no-log "** * Test: ASK --allow-empty * **"
  MESSAGE ${msg_opt} --no-log "  Just hit ENTER for this test, and check that the response is an empty string"
  ASK     ${msg_opt} --allow-empty result "Want to say something ?"
  MESSAGE ${msg_opt} --no-log "You have type \"${result}\""
  MESSAGE ${msg_opt} --no-log ''

  check_LOG_FILE 'Want to say something ? =>'
  [ "${result}" != '' ] && TEST_FAILED


  result=
  MESSAGE ${msg_opt} --no-log "** * Test: ASK --with-break and --useless-option * **"
  MESSAGE ${msg_opt} --no-log "  A LineBreak is added after the question"
  ASK     ${msg_opt} --with-break --useless-option result "Want to say something ?"
  MESSAGE ${msg_opt} --no-log "You have type \"${result}\""
  MESSAGE ${msg_opt} --no-log ''

  check_LOG_FILE "Want to say something ? => ${result}"


  if [ "${loop_count}" = "0" ]; then
    ASK_SET_AUTOANSWER_FILE "${TEST_ANSWER_FILE}"
    msg_opt="--no-print"
    MESSAGE --no-log '** * Test: ASK with automatic answer file * **'
  fi

  loop_count=$(( loop_count + 1))
done

rm -f "${TEST_FILE}" "${TEST_ANSWER_FILE}"
exit 0
