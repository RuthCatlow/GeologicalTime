#!/bin/bash

kill -9 $(ps aux | grep '[m]unge.sh' | awk '{print $2}')
kill -9 $(ps aux | grep '[f]fmpeg' | awk '{print $2}')
