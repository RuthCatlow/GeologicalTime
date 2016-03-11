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

if [ -z "$1" ] || [ "$1" != "nogit" ]
then
  cd $ROOT && git stash && git pull origin master
fi

# DEBUG
# rm ${ROOT}output/videos/video-{01737..1750}.mp4 -if
# rm ${ROOT}output/write/out{01737..1750}.png -if

SRCTOTAL=`ls output/write/*.png | wc -l`
echo {\"count\":$((SRCTOTAL)), \"time\":0} > output/count.json

${PROCESSING} ${ROOT}collection/collection.pde
