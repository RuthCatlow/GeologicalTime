#!/bin/bash
# echo "${1}/write/*.png"

WRITEDIR=write
OTHERDIRECTORY=${1}/images/2016-03-11/*.png

SRCTOTAL=`ls ${1}/${WRITEDIR}/*.png | wc -l`
OTHERTOTAL=`ls $OTHERDIRECTORY | wc -l`
echo $OTHERTOTAL

IMAGES=( ${1}/${WRITEDIR}/*.png )
INDICES=( ${!IMAGES[@]} )
for ((i=${#INDICES[@]} - 1; i >= 0; i--))
do
  IMAGE=${IMAGES[INDICES[i]]}
  NUMPAD=`expr match "$IMAGE" '[^0-9]*\([0-9]\+\).*'`
  NUM=$(echo $NUMPAD | sed 's/^0*//')
  INCREMENTEDPAD=`printf "%05d" $((NUM+OTHERTOTAL))`
  echo ${IMAGE/$NUMPAD/$INCREMENTEDPAD}
  mv $IMAGE ${IMAGE/$NUMPAD/$INCREMENTEDPAD}
done

for f in `ls ${OTHERDIRECTORY}`;
do
  # OTHERIMAGE=${OTHERIMAGES[OTHERINDICES[i]]}
  NEWFILENAME=`printf "${1}/${WRITEDIR}/out%05d.png" $OTHERTOTAL`
  echo "$NEWFILENAME from $f"
  cp $f $NEWFILENAME
  OTHERTOTAL=$((OTHERTOTAL-1))
done;

exit 1
