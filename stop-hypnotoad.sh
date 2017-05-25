#!/bin/sh
CDSP=/home/ivo/bitsyllabus/syllabus.space/
echo "Stopping hypnotoad from $CDSP"
cd $CDSP
/usr/local/bin/hypnotoad -s $CDSP/SylSpace
