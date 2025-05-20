#!/bin/bash

function getdir(){
    for file in ../*.v
    do
	export INFILE=$file
        dir=${file##*/}
	name=${dir%.*}
        echo $name
	export REPORT=$name
        #arr=(${arr[*]} $file)
	dc_shell-xg-t -f $SCRIPTFILE
	echo "**********************************************" >> output0201_VTS.txt
	echo $name >> output0201_VTS.txt
	cat ./Reports/${name}_area.rpt | grep "Total cell area" >> output0201_VTS.txt
	cat ./Reports/${name}_timing.rpt | grep -m1 -i "Data arrival time" >> output0201_VTS.txt
	cat ./Reports/${name}_power.rpt | tail -6 | head -5 >> output0201_VTS.txt
	echo -e "\n" >> output0201_VTS.txt
    done
}
export SCRIPTFILE=./run_dc.tcl

getdir ../
#for ((i=0; i<50; i++)); do
#    rm output_$i.txt
#    getdir ../Results $i 
#done

