#
# Copyright (c) 2006-2010 Linagora
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
# README ---------------------------------------------------------------------
#
# CLI_REGISTER_COMMAND()
#   usage: CLI_REGISTER_COMMAND "<cli_command>" <function>
#   desc: register a cli command <cli_command>, which may call the <function>
#   note: commands, registered with this method, will take care of the CLI context
#
# CLI_REGISTER_COMMAND()
#   usage: CLI_REGISTER_COMMAND "<cli_command>" <function>
#   desc: register a cli command <cli_command>, which may call the <function>
#         and don't take care of the CLI context
#
# CLI_REGISTER_MENU()
#   usage: CLI_REGISTER_MENU "<cli_menu>"
#   desc: register a cli menu, which will be added at the beginnig of new CLI command.
#
# CLI_SET_PROMPT()
#   usage: CLI_SET_PROMPT "<string>"
#   desc: set the CLI prompt
#
# CLI_USE_READLINE()
#   usage: CLI_USE_READLINE <options>
#   desc: Enable the readline functionnalities of read
#
# CLI_RUN_COMMAND()
#   usage: CLI_RUN_COMMAND <command>
#   desc: Run a single command into the CLI
#   alias: CLI_RUN_CMD
#   note: this function return 0 if a valid CLI command is passed in argument, otherwise 1
#
# CLI_RUN()
#   usage: CLI_RUN
#   desc: Run the CLI
#   note: this function add some "sugar" CLI command, like 'quit', 'exit',
#         and deal with CLI context menu for command registered with CLI_REGISTER_COMMAND()

if [ "${__LIB_CLI__:-}" != 'Loaded' ]; then
  __LIB_CLI__='Loaded';

  # Load command lib
  if [ "${__LIB_MESSAGE__:-}" != 'Loaded' ]; then
    if [ -r ./message.lib.sh ]; then
      . ./message.lib.sh
    else
      echo "ERROR: Unable to load ./message.lib.sh library"
      exit 2
    fi
  fi

  # Load ask lib
  if [ "${__LIB_ASK__:-}" != 'Loaded' ]; then
    if [ -r ./ask.lib.sh ]; then
      . ./ask.lib.sh
    else
      echo "ERROR: Unable to load ./ask.lib.sh library"
      exit 2
    fi
  fi

  # Internal variables
  # ---------------------------------------------------
  # Do not write to those vairables.
  __CLI_CODE__=
  __CLI_KCODE__=
  __CLI_PROMPT__=
  __CLI_CONTEXT_MENU__=

  # determine a good sed separator
  private_SED_SEPARATOR () {
    for s in '/' '@' ',' '|'; do
      if [ "${1//$s/}" = "$1" ]; then
        echo "$s"; return 0;
      fi
    done
    return 1;
  }

  # build a sed pattern for parsing CLI command
  private_BUILD_SED_COMMAND () {
    echo -n "^"
    echo "$1" | tr ' ' $'\n' \
      | while read word; do
          [ -z "${word}" ] && continue
          [ "${word}" = '?' ] && word="\([^ ]*\)"
          echo -n " *${word}"
        done
    echo " *$"
  }

  CLI_SET_PROMPT () { __CLI_PROMPT__="$1"; }
  CLI_USE_READLINE () { ASK_ENABLE_READLINE $@; }

  CLI_REGISTER_COMMAND () {
    [ $# -ne 2 ] && ERROR "CLI_REGISTER_COMMAND: invalid arguments"
    private_CLI_COMPIL "$1" "$2" "__CLI_CODE__"
  }

  CLI_REGISTER_KCOMMAND() {
    [ $# -ne 2 ] && ERROR "CLI_REGISTER_KCOMMAND: invalid arguments"
    private_CLI_COMPIL "$1" "$2" "__CLI_KCODE__"
  }

  private_CLI_COMPIL() {
    local cli_cmd="$1" func="$2" code="$3" sep=

    # delete trailing space
    cli_cmd="${cli_cmd%% }"; cli_cmd="${cli_cmd## }"
    func="${func%% }"; func="${func## }"

    [ "${cli_cmd:-}" = '' -o "${func:-}" = '' ] && ERROR "CLI_REGISTER_COMMAND: invalid arguments"

    sep=$( private_SED_SEPARATOR "${cli_cmd}" )
    cli_cmd=$( private_BUILD_SED_COMMAND "${cli_cmd}" )
    func=$( echo "${func}" | sed -e "s/\([\\][0-9]\)/'\1'/g" )

    # update the code
    eval "$code=\"${!code} s${sep}${cli_cmd}${sep}${func}${sep}p; t;\""
  }

  CLI_REGISTER_MENU () {
    local cli_menu= sep=
    [ $# -ne 1 ] && ERROR "CLI_REGISTER_MENU: invalid arguments"
    cli_menu="$1"

    sep=$( private_SED_SEPARATOR "${cli_menu}" )
    cli_menu=$( private_BUILD_SED_COMMAND "${cli_menu}" )

    __CLI_CODE__="${__CLI_CODE__} s${sep}\(${cli_menu}\)${sep}CLI_ENTER_MENU \1${sep}p; t;"
  }


  CLI_RUN_COMMAND () {
    local cmd=
    [ $# -eq 0 ] && return;

    cmd=$( echo "$*" | sed -n -e "${__CLI_KCODE__}" )
    [ -z "${cmd}" ] && cmd=$( echo "$*" | sed -n -e "${__CLI_CODE__}" )

    if [ -n "${cmd}" ]; then
      eval "${cmd}"
      return $?
    fi
    return 1;
  }
  CLI_RUN_CMD() { CLI_RUN_COMMAND $@; return $? }

  CLI_RUN () {
    CLI_UNKNOWN_COMMAND () { ERROR "Unknown CLI command"; }
    CLI_ENTER_MENU () { __CLI_CONTEXT_MENU__="$*"; }
    CLI_QUIT='[ -z "${__CLI_CONTEXT_MENU__:-}" ] \&\& break || __CLI_CONTEXT_MENU__= '

    local kcode= code= input= cmd=

    code="${__CLI_CODE__} ; a \ CLI_UNKNOWN_COMMAND;"

    # internal CLI special commands
    kcode="${__CLI_KCODE__}"
    kcode="${kcode} s/^ *quit *$/${CLI_QUIT}/p; t;"
    kcode="${kcode} s/^ *exit *$/break/p; t;"

    while [ true ]; do
      ASK --allow-empty input "${__CLI_PROMPT__} ${__CLI_CONTEXT_MENU__:+[${__CLI_CONTEXT_MENU__}]}>"
      [ -z "${input}" ] && continue
      cmd=$( echo "${input}" | sed -n -e "${kcode}" )
      [ -z "${cmd}" ] && \
        cmd=$( echo "${__CLI_CONTEXT_MENU__} ${input}" | sed -n -e "${code}" )
      eval "${cmd}"
    done

    return 0;
  }

fi # end of: if [ "${__LIB_CLI__:-}" != 'Loaded' ]; then
