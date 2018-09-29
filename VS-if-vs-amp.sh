#!/bin/sh

##
# Output UTC date for log
# EnvironmentVariables:
#   no
# Arguments:
#   no
# Stdin:
#   no
# Stdout:
#   string UTC date ISO 8601 format
# Stderr:
#   no
# Return:
#   0 always
##
PrintDateUTC() { (
  LC_ALL=C TZ=UTC date +'%Y%m%dT%H%M%SZ'
)}

##
# Output log
# EnvironmentVariables:
#   no
# Arguments:
#   $1 log level
#   $2 log message
# Stdin:
#   no
# Stdout:
#   no
# Stderr:
#   string log message
# Return:
#   0 always
##
PrintErrLog() { (
  # vars
  level="${1:?"$(PrintDateUTC) [FATAL] PrintErrLog(): requires \"level\" as \$1"}"
  logMessages="${2:?"$(PrintDateUTC) [FATAL] PrintErrLog(): requires \"logMessages\" as \$2"}"

  # check level
  case "${level}" in
    f|F) tag='[FATAL]' ;;
    e|E) tag='[ERROR]' ;;
    w|W) tag='[WARN] ' ;;
    d|D) tag='[DEBUG]' ;;
      *) tag='[INFO] ' ;;
  esac

  # output log message to stderr
  printf '%s\n' "${logMessages}" | sed "s/^/$(PrintDateUTC) ${PROGRAM_NAME}[$$]: ${tag} /" >/dev/stderr
)}

readonly TIMES=100000

PrintErrLog I "time of \"if x ${TIMES}\": $(time \
  (
    for i in $(seq 1 "${TIMES}"); do
      if [ "$i" -le 10000 ]; then
        :
      else
        :
      fi
    done
  ) 2>&1
)"

PrintErrLog I "time of \"&& x ${TIMES}\": $(time \
  (
    for i in $(seq 1 "${TIMES}"); do
      [ "$i" -le 10000 ] && { :; } || { :; }
    done
  ) 2>&1
)"

PrintErrLog I "多分ifの方が早い"
