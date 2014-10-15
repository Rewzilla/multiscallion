#!/bin/sh


##### CONFIG #####

# How many GPUs do you have?
GPU_COUNT=2

# Where is your scallion.exe binary located?
SCALLION="/opt/scallion/bin/Debug/scallion.exe"

# Temp file to store things.  (Probably don't change this)
TMP_FILE="/tmp/scallion.hash"

# Don't forget to install mono!
### END CONFIG ###


if [[ $# != 1 ]];
then
	echo "Usage "$0" [pattern]"
	exit
fi

cleanup() {
	echo "Cleaning up..."

	echo -n "   - Killing scallions... "
	for p in ${PID[@]}
	do
	        kill -9 $p >/dev/null 2>&1
	done
	echo "done"

	echo -n "   - Removing temp file... "
        rm $TMP_FILE > /dev/null 2>&1
	echo "done"
	exit
}

trap cleanup SIGINT

DEVICES=()
PATTERN=$1

for (( c=0; c<$GPU_COUNT; c++ ));
do
	DEVICES=("${DEVICES[@]}" $c)
done

for d in ${DEVICES[@]}
do
	echo -n "Starting scallion on GPU$d"
	eval "mono $SCALLION -d $d -o $TMP_FILE $PATTERN >/dev/null 2>&1 &"
	PID[$d]=$!
	echo " pid="${PID[$d]}
done

echo "Waiting for $PATTERN ... "
while [ ! -f $TMP_FILE ]
do
        for p in ${PID[@]}
        do
                if ! ps -p $p > /dev/null;
                then
                        echo "Scallion proccess is dead.  Did you mess up the regex?"
                        cleanup
                fi
        done
done

cat $TMP_FILE

cleanup

