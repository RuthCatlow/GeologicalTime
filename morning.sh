#!/bin/bash

if [ "$USER" = "gareth" ]
then
  ROOT=/home/gareth/Projects/GEOLOGICALTIME/
  PROCESSING=/home/gareth/Dropbox/Dev/processing/processing-3.0b2/processing
else
  ROOT=/home/furtherfield/Desktop/GeologicalTime/
  PROCESSING=/home/furtherfield/Desktop/processing-3.0.1/processing
fi

rm ${ROOT}output/tmp/* -if
cd $ROOT & git stash & git pull origin master

${PROCESSING} ${ROOT}collection/collection.pde

