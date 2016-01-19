#!/bin/bash

if [ "$USER" = "gareth" ]
then
  ROOT=/home/gareth/Projects/GEOLOGICALTIME/
  PROCESSING=/home/gareth/Dropbox/Dev/processing/processing-3.0b2/processing
else
  ROOT=/home/furtherfield/Desktop/GeologicalTime/
  PROCESSING=/home/furtherfield/Desktop/processing-3.0.1/processing
fi

cd $ROOT && git add collection/cams.txt && git commit -m "Latest cams" && git push origin master
