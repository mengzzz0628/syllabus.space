#!/bin/sh
CDSP=/home/ivo/bitsyllabus/syllabus.space/
echo "Running morbo from $CDSP"
cd $CDSP
/usr/local/bin/morbo -v -m production $CDSP/SylSpace -l http://syllabus.space:80
