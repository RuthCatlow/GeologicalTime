#!/bin/bash

if [ "$USER" = "gareth" ]
then
  ROOT=/home/gareth/Projects/GEOLOGICALTIME/
  PROCESSING=/home/gareth/Dropbox/Dev/processing/processing-3.0b2/processing
else
  ROOT=/home/furtherfield/Desktop/GeologicalTime/
  PROCESSING=/home/furtherfield/Desktop/processing-3.0.1/processing
fi

# rm ${ROOT}output/tmp/* -if

if [ -z "$1" ] || [ "$1" != "nogit" ]
then
  cd $ROOT && git stash && git pull origin master
fi

curl http://gtp.ruthcatlow.net/count.json > output/count.json

${PROCESSING} ${ROOT}collection/collection.pde
