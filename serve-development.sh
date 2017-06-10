#!/bin/sh
set -v
if [ "$HOSTNAME" = syllabus-space ]; then
CDSP=/home/ivo/bitsyllabus/syllabus.space/
echo "Running morbo from $CDSP"
cd $CDSP
/usr/local/bin/morbo -v -m development $CDSP/SylSpace -l http://syllabus.space:80
else
CDSP=/Users/ivo/bitsyllabus/syllabus.space/
cd $CDSP
echo "Running morbo from $CDSP"
echo "/usr/local/bin/morbo -v -m development ./SylSpace -l http://syllabus.test:80"
echo "--- this fails! do by hand"
/usr/local/bin/morbo -v -m development ./SylSpace -l http://syllabus.test:80
fi
