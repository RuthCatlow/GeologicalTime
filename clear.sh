#!/bin/bash

source ./munge/.env

read -p "DANGER! You are about to remove all images and videos. Are you sure? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
  cp /dev/null munge/munge.log
  cp /dev/null munge/ftp.log
  rm collection/{cams,log}.txt
  rm output/{images,videos}/*
  rm output/{write,tmp}/ -r
  rm output/count.json
  ssh ruth@gtp.ruthcatlow.net "rm ${GTP_BASE_DIR}{images,videos}/*; rm ${GTP_BASE_DIR}count.json"
fi