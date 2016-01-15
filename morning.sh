#!/bin/bash

ROOT=/home/gareth/Projects/GEOLOGICALTIME/
# ROOT=/home/furtherfield/Desktop/GeologicalTime/
rm ${ROOT}output/tmp/* -i
rm ${ROOT}output/count.json -i

cd $ROOT & git stash & git pull origin master
