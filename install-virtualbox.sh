#!/bin/sh

## If an error occurs, EXIT abnormally.
#set -e

# Global variables
readonly __MYSH_VERSION='0.0.1'
readonly __MYSH_PROGRAM_NAME="$(basename -- "$0")"
readonly __MYSH_PROJECT_NAME='orderqr'
readonly __MYSH_APPLICATIONS_DIR='/Applications/VirtualBox.app'
readonly __MYSH_DMG_URI='http://download.virtualbox.org/virtualbox/5.2.18/VirtualBox-5.2.18-124319-OSX.dmg'
readonly __MYSH_WORK_DIR="${HOME}/Desktop/${__MYSH_PROJECT_NAME}"
readonly __MYSH_DOWNLOADS_DIR="${__MYSH_WORK_DIR}/downloads"
readonly __MYSH_DMG_LOCAL_PATH="${__MYSH_DOWNLOADS_DIR}/$(basename -- ${__MYSH_DMG_URI})"
readonly __MYSH_HDIUTIL_VOLUMES_PATH='/Volumes/VirtualBox'
readonly __MYSH_HDIUTIL_PKG_PATH="${__MYSH_HDIUTIL_VOLUMES_PATH}/VirtualBox.pkg"

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
  LC_ALL=C TZ=UTC date +%Y%m%dT%H%M%SZ
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
  printf '%s\n' "${logMessages}" | sed "s/^/$(PrintDateUTC) ${__MYSH_PROGRAM_NAME}[$$]: ${tag} /" >/dev/stderr
)}

main() {
  # OSの確認 (macOSのみサポート)
  if ! { uname -s | grep -q ^Darwin$; }; then
    PrintErrLog E 'support only macOS'
    return 1
  fi

  # 既にインストールされているかどうか確認
  if [ -d "${__MYSH_APPLICATIONS_DIR}" ]; then
    PrintErrLog I "already installed: ${__MYSH_APPLICATIONS_DIR}"
    return 0
  fi

  # sudo validation
  PrintErrLog I 'Please enter the administrator password.'
  sudo -v || exit 1

  # 既にインストーラーがダウンロードされているか確認
  if [ -f "${__MYSH_DMG_LOCAL_PATH}" ]; then
    PrintErrLog I "already downloaded: ${__MYSH_DMG_LOCAL_PATH}"
  else
    # ダウンロード用ディレクトリ作成
    mkdir -p "${__MYSH_DOWNLOADS_DIR}"

    # ダウンロード
    PrintErrLog I "try to download ${__MYSH_DMG_URI} ..."
    curl -LR "${__MYSH_DMG_URI}" -o "${__MYSH_DMG_LOCAL_PATH}"
    if [ $? -eq 0 ]; then
      PrintErrLog I "complete to download ${__MYSH_DMG_LOCAL_PATH}"
    else
      PrintErrLog E "failed to download: ${__MYSH_DMG_URI}"
      rm -f "${__MYSH_DMG_LOCAL_PATH}"
      return 1
    fi
  fi

  # インストール
  PrintErrLog I "try to install ${__MYSH_DMG_LOCAL_PATH} ..."
  hdiutil mount "${__MYSH_DMG_LOCAL_PATH}"
  sudo installer -pkg "${__MYSH_HDIUTIL_PKG_PATH}" -target / -lang ja
  hdiutil detach "${__MYSH_HDIUTIL_VOLUMES_PATH}"

  # インストールされたか確認
  if [ -d "${__MYSH_APPLICATIONS_DIR}" ]; then
    PrintErrLog I "complete to install: ${__MYSH_APPLICATIONS_DIR}"
    return 0
  else
    PrintErrLog E "failed to install: ${__MYSH_APPLICATIONS_DIR}"
    return 1
  fi
}

##
# Execute the main function.
# It is executed first in this script.
#
# $@ ... Pass all the arguments of the laws command.
##
main "$@"
