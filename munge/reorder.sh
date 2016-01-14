#!/bin/bash
# echo "${1}/write/*.png"

SRCTOTAL=`ls ${1}/write/*.png | wc -l`
NEWFILE=`printf "${1}/tmp/out%05d.png" $((SRCTOTAL+1))`

IMAGES=( ${1}/write/*.png )
INDICES=( ${!IMAGES[@]} )
for ((i=${#INDICES[@]} - 1; i >= 0; i--))
do
  IMAGE=${IMAGES[INDICES[i]]}
  NUMPAD=`expr match "$IMAGE" '[^0-9]*\([0-9]\+\).*'`
  NUM=$(echo $NUMPAD | sed 's/^0*//')
  INCREMENTEDPAD=`printf "%05d" $((NUM+1))`
  # echo ${IMAGE/$NUMPAD/$INCREMENTEDPAD}
  mv $IMAGE ${IMAGE/$NUMPAD/$INCREMENTEDPAD}
done

cp $NEWFILE "${1}/write/out00001.png"
exit 1
