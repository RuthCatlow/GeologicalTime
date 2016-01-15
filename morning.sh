#!/bin/bash

echo $USER
if [ "$USER" = "gareth" ]
then
  ROOT=/home/gareth/Projects/GEOLOGICALTIME/
  PROCESSING=/home/gareth/Dropbox/Dev/processing/processing-3.0b2/processing
else
  ROOT=/home/furtherfield/Desktop/GeologicalTime/
  PROCESSING=/home/gareth/Desktop/processing-3.0.1/processing
fi

rm ${ROOT}output/tmp/* -i
rm ${ROOT}output/count.json -i
cd $ROOT & git stash & git pull origin master

${PROCESSING} ${ROOT}collection/collection.pde

