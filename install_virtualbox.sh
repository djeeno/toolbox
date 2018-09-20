#!/bin/sh

## If an error occurs, EXIT abnormally.
#set -e

# sudo validation
sudo -v || exit 1

# Global variables
readonly VERSION='0.0.1'
readonly PROGRAM_NAME="$(basename -- "$0")"
readonly PROJECT_NAME='orderqr'
readonly VIRTUALBOX_DMG_URI='http://download.virtualbox.org/virtualbox/5.2.18/VirtualBox-5.2.18-124319-OSX.dmg'
readonly WORK_DIR="${HOME}/Desktop/${PROJECT_NAME}"
readonly DOWNLOADS_DIR="${WORK_DIR}/downloads"
readonly VIRTUALBOX_DMG_LOCAL_PATH="${DOWNLOADS_DIR}/$(basename -- ${VIRTUALBOX_DMG_URI})"
readonly VIRTUALBOX_HDIUTIL_VOLUMES_PATH='/Volumes/VirtualBox'
readonly VIRTUALBOX_HDIUTIL_PKG_PATH="${VIRTUALBOX_HDIUTIL_VOLUMES_PATH}/VirtualBox.pkg"

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

  # 既にVirtualBoxがインストールされているかどうか確認
  if [ -d /Applications/VirtualBox.app ]; then
    PrintErrLog I 'already installed: /Applications/VirtualBox.app'
    return 0
  fi

  # 既にVirtualBoxのインストーラーがダウンロードされているか確認
  if [ -f "${VIRTUALBOX_DMG_LOCAL_PATH}" ]; then
    PrintErrLog I "already downloaded: ${VIRTUALBOX_DMG_LOCAL_PATH}"
  else
    # ダウンロード用ディレクトリ作成
    mkdir -p "${DOWNLOADS_DIR}"

    # ダウンロード
    PrintErrLog I "try to download ${VIRTUALBOX_DMG_URI} ..."
    curl -LR "${VIRTUALBOX_DMG_URI}" -o "${VIRTUALBOX_DMG_LOCAL_PATH}"
    if [ $? -eq 0 ]; then
      PrintErrLog I "complete to download ${VIRTUALBOX_DMG_LOCAL_PATH}"
    else
      PrintErrLog E "failed to download: ${VIRTUALBOX_DMG_URI}"
      rm -f "${VIRTUALBOX_DMG_LOCAL_PATH}"
      return 1
    fi
  fi

  # VirtualBox インストール
  PrintErrLog I "try to install ${VIRTUALBOX_DMG_LOCAL_PATH} ..."
  hdiutil mount "${VIRTUALBOX_DMG_LOCAL_PATH}"
  sudo installer -pkg "${VIRTUALBOX_HDIUTIL_PKG_PATH}" -target / -lang ja
  hdiutil detach "${VIRTUALBOX_HDIUTIL_VOLUMES_PATH}"

  # インストールされたか確認
  if [ -d /Applications/VirtualBox.app ]; then
    PrintErrLog I 'complete to install: /Applications/VirtualBox.app'
    return 0
  else
    PrintErrLog E 'failed to install: /Applications/VirtualBox.app'
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
