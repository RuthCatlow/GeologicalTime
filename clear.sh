#!/bin/bash

source ./munge/.env

read -p "DANGER! You are about to remove all images and videos. Are you sure? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
  cp /dev/null munge/munge.log
  cp /dev/null munge/ftp.log
  rm collection/{cams,log}.txt
  ARCHIVE=archive$(date +%Y%m%d%H%M)
  mkdir $ARCHIVE -p
  mv output/{write,images,videos} $ARCHIVE
  rm output/tmp/ -r
  rm output/count.json
  mkdir output/{images,videos}
  ssh ruth@gtp.ruthcatlow.net "mkdir ${GTP_BASE_DIR}archive/ -p; mv ${GTP_BASE_DIR}{images,videos} ${GTP_BASE_DIR}archive/; mv ${GTP_BASE_DIR}count.json ${GTP_BASE_DIR}archive/; mkdir ${GTP_BASE_DIR}{images,videos}"
fi
