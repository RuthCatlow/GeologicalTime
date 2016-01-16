#!/bin/bash

source ./munge/.env

if [ "$USER" = "gareth" ]
then
  ROOT=/home/gareth/Projects/GEOLOGICALTIME/
else
  ROOT=/home/furtherfield/Desktop/GeologicalTime/
fi

cp /dev/null ${ROOT}munge/munge.log
cp /dev/null ${ROOT}munge/ftp.log
rm ${ROOT}collection/{cams,log}.txt
ARCHIVE=${ROOT}archive$(date +%Y%m%d%H%M)
mkdir $ARCHIVE -p
mv ${ROOT}output/{write,images,videos} $ARCHIVE
rm ${ROOT}output/tmp/ -r
rm ${ROOT}output/count.json
mkdir ${ROOT}output/{images,videos}
# ssh ruth@gtp.ruthcatlow.net "mkdir ${GTP_BASE_DIR}archive/ -p; mv ${GTP_BASE_DIR}{images,videos} ${GTP_BASE_DIR}archive/; mv ${GTP_BASE_DIR}count.json ${GTP_BASE_DIR}archive/; mkdir ${GTP_BASE_DIR}{images,videos}"
