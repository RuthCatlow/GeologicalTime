#!/bin/bash

TOTAL=`ls output/write/*.png | wc -l`
NEWTOTAL=1733
DIFF=`expr $TOTAL - $NEWTOTAL`

# Remove the last files created (lowest numbers)
for i in $(seq 1 $DIFF);
do
  IMAGEFILE=output/write/out`printf "%05d" $i`.png
  VIDEOINDEX=`expr $NEWTOTAL + $i`
  VIDEOFILE=`printf "output/videos/video-%05d.mp4" $VIDEOINDEX`
  rm $IMAGEFILE -f
  echo "DELETE IMAGE $IMAGEFILE"
  rm $VIDEOFILE -f
  echo "DELETE VIDEO $VIDEOFILE"
done

# Reorder files.
COUNT=1
for f in `ls -v output/write/*.png`;
do
  FILE=output/write/out`printf "%05d" $COUNT`.png
  if [ "$f" != "$FILE" ]; then
    echo "MOVE $f to $FILE"
    mv $f $FILE
  fi

  COUNT=$((COUNT+1))
done;

exit 1
