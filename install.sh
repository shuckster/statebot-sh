#!/bin/sh

TMP_FOLDER="/tmp"
TMP_ARCHIVE="statebot-sh.zip"
STATEBOT_SH_ZIP="https://github.com/shuckster/statebot-sh/archive/master.zip"
SCRATCH_FOLDER="${TMP_FOLDER}/statebot-sh-master"
INSTALL_FOLDER="/opt/statebot"

main()
{
  cd ${TMP_FOLDER} || failed_cd_tmp

  echo "Download and install Statebot-sh to '${INSTALL_FOLDER}'?"
  printf "Type 'yes' to confirm: "
  read -r CONFIRM

  if [ "${CONFIRM}" != "yes" ]
  then
    echo "[BAIL]"
    exit 1
  fi

  test -d ${INSTALL_FOLDER} && failed_already_installed
  curl -L ${STATEBOT_SH_ZIP} > ${TMP_ARCHIVE} || failed_curl
  unzip ${TMP_ARCHIVE} || failed_unzip
  rm ${TMP_ARCHIVE}
  mkdir /opt 2> /dev/null
  mv ${SCRATCH_FOLDER} ${INSTALL_FOLDER} || failed_mv

  echo "Installed! Running tests to see if Statebot-sh will work for you..."
  cd ${INSTALL_FOLDER} && ./tests/all.sh
}

failed_cd_tmp()
{
  echo "Could not cd to ${TMP_FOLDER}"
  exit 255
}

failed_curl()
{
  echo "Could not download ${STATEBOT_SH_ZIP}"
  exit 254
}

failed_unzip()
{
  echo "Could not unzip ${TMP_ARCHIVE} into ${TMP_FOLDER}"
  exit 253
}

failed_mv()
{
  echo "Could not move ${SCRATCH_FOLDER} to ${INSTALL_FOLDER}"
  exit 252
}

failed_already_installed()
{
  echo "Something already exists at: ${INSTALL_FOLDER}"
  echo "Please move/remove it first"
  exit 251
}

main
