#!/bin/sh

## If an error occurs, EXIT abnormally.
#set -e

# sudo validation
sudo -v || exit 1

# Global variables
readonly VERSION='0.0.1'
readonly PROGRAM_NAME="$(basename -- "$0")"
readonly PROJECT_NAME='orderqr'
readonly APPLICATIONS_DIR='/opt/vagrant'
readonly DMG_URI='https://releases.hashicorp.com/vagrant/2.1.5/vagrant_2.1.5_x86_64.dmg'
readonly WORK_DIR="${HOME}/Desktop/${PROJECT_NAME}"
readonly DOWNLOADS_DIR="${WORK_DIR}/downloads"
readonly DMG_LOCAL_PATH="${DOWNLOADS_DIR}/$(basename -- ${DMG_URI})"
readonly HDIUTIL_VOLUMES_PATH='/Volumes/Vagrant'
readonly HDIUTIL_PKG_PATH="${HDIUTIL_VOLUMES_PATH}/Vagrant.pkg"

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

main() {
  # OSの確認 (macOSのみサポート)
  if ! { uname -s | grep -q ^Darwin$; }; then
    PrintErrLog E 'support only macOS'
    return 1
  fi

  # 既にインストールされているかどうか確認
  if [ -d "${APPLICATIONS_DIR}" ]; then
    PrintErrLog I "already installed: ${APPLICATIONS_DIR}"
    return 0
  fi

  # 既にインストーラーがダウンロードされているか確認
  if [ -f "${DMG_LOCAL_PATH}" ]; then
    PrintErrLog I "already downloaded: ${DMG_LOCAL_PATH}"
  else
    # ダウンロード用ディレクトリ作成
    mkdir -p "${DOWNLOADS_DIR}"

    # ダウンロード
    PrintErrLog I "try to download ${DMG_URI} ..."
    curl -LR "${DMG_URI}" -o "${DMG_LOCAL_PATH}"
    if [ $? -eq 0 ]; then
      PrintErrLog I "complete to download ${DMG_LOCAL_PATH}"
    else
      PrintErrLog E "failed to download: ${DMG_URI}"
      rm -f "${DMG_LOCAL_PATH}"
      return 1
    fi
  fi

  # インストール
  PrintErrLog I "try to install ${DMG_LOCAL_PATH} ..."
  hdiutil mount "${DMG_LOCAL_PATH}"
  sudo installer -pkg "${HDIUTIL_PKG_PATH}" -target / -lang ja
  hdiutil detach "${HDIUTIL_VOLUMES_PATH}"

  # インストールされたか確認
  if [ -d "${APPLICATIONS_DIR}" ]; then
    PrintErrLog I "complete to install: ${APPLICATIONS_DIR}"
    return 0
  else
    PrintErrLog E "failed to install: ${APPLICATIONS_DIR}"
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
