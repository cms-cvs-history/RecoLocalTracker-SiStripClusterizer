#!/bin/sh

function unpack(){
    echo -e "&&&&&&&&&&&&&&&&\nUpacking files from $tar_path\n&&&&&&&&&&&&&&&&\n"
    cd $tar_path
    for file in `ls *.tar.gz`
	do
	echo $file
	runNum=`echo $file | sed -e "s#[^0-9]##g"`
	tar xvzf $file \*RU\*root
	mv ${runNum}/* $runs_path
	rm -rf ${runNum}
	ls 
    done
    cd -

}


function runPedestals(){
    echo -e "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&\nRunning Pedestals on files in $pedestals_path/PedestalRuns_List.dat\n&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&\n"

    grep -v "\#" $pedestals_path/PedestalRuns_List.dat 

    fedconnections=(`grep -v "\#" $pedestals_path/PedestalRuns_List.dat | awk -F"|" '{print $1}'`)
    pedRuns=(`grep -v "\#" $pedestals_path/PedestalRuns_List.dat | awk -F"|" '{print $2}'`)
    iov=(`grep -v "\#" $pedestals_path/PedestalRuns_List.dat | awk -F"|" '{print $3}'`)
    
    Ndim=${#iov[@]}

    #loop on entries
    i=0
    while [ $i -lt $Ndim ]
      do
      echo ${pedRuns[$i]} " " ${iov[$i]}

      #Create input file list
      firstRun=`echo ${pedRuns[$i]} | awk -F":" '{print $1}'`
      lastRun=`echo ${pedRuns[$i]} | awk -F":" '{ if ($2 != "" ) print $2; else print $1}'`
      inputfilenames=""
      while [ ${firstRun} -le ${lastRun} ]
	do
	for file in `ls ${runs_path}/*${firstRun}*root`
	  do
	  inputfilenames="${inputfilenames},\"file:$file\""
	  done
	let firstRun++
      done
      inputfilenames=`echo $inputfilenames | sed -e "s@,@@"`
      echo $inputfilenames

      #get iov
      iovfirstRun=`echo ${iov[$i]} | awk -F":" '{print $1}'`
      iovlastRun=`echo ${iov[$i]} | awk -F":" '{ if ($2 != "" ) print $2; else print $1}'`

      cat $cfg_path/template_mtcc_pedestals.cfg | sed -e "s@insert_fedconnection_description@${fedconnections_path}/${fedconnections}.dat@" | sed -e "s@insert_input_filenames@${inputfilenames}@" | sed -e "s@insert_SiStripPedNoisesDB@${pedestals_path}/SiStripPedNoises.db@" | sed -e "s@insert_SiStripPedNoisesCatalog@${pedestals_path}/SiStripPedNoises.db@" | sed -e "s@insert_iovfirstRun@${iovfirstRun}@" | sed -e "s@insert_iovlastRun@${iovlastRun}@" > $cfg_path/mtcc_pedestals_${pedRuns[$i]}.cfg


      echo cmsRun $cfg_path/mtcc_pedestals_${pedRuns[$i]}.cfg
      cmsRun $cfg_path/mtcc_pedestals_${pedRuns[$i]}.cfg
      exit_status=$?
      
      if [ "$exit_status" == "0" ];
	  then
	  cat $pedestals_path/PedestalRuns_List.dat | sed -re "s@(${fedconnections[$i]}\s*\|\s*${pedRuns[$i]}\s*\|\s*${iov[$i]})@#&@g" >> file.tmp
	  mv -f file.tmp $pedestals_path/PedestalRuns_List.dat
      else
	  echo -e "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&\nERROR Running Pedestals on cfg "
	  cat $cfg_path/mtcc_pedestals_${pedRuns[$i]}.cfg
	  echo -e "\n&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&\n"

      fi

      let i++
    done
}

function runPhysics(){
    echo -e "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&\nRunning Analysis on Physics Runs on files\n&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&\n"

    fedconnections=$1
    firstRun=$2
    lastRun=$3

    inputfilenames=""
    while [ ${firstRun} -le ${lastRun} ]
      do
      for file in `ls ${runs_path}/*${firstRun}*root`
	do
	inputfilenames="${inputfilenames},\"file:$file\""
      done
      let firstRun++
    done
    inputfilenames=`echo $inputfilenames | sed -e "s@,@@"`
    echo $inputfilenames

    cat $cfg_path/template_mtcc_physics.cfg | sed -e "s@insert_fedconnection_description@${fedconnections_path}/${fedconnections}.dat@" | sed -e "s@insert_input_filenames@${inputfilenames}@" | sed -e "s@insert_SiStripPedNoisesDB@${pedestals_path}/SiStripPedNoises.db@" | sed -e "s@insert_SiStripPedNoisesCatalog@${pedestals_path}/SiStripPedNoises.db@" | sed -e "s@insert_outputfilename@${outputfilename}@" > $cfg_path/mtcc_physics_${firstRun}_${lastRun}.cfg

      echo cmsRun $cfg_path/mtcc_physics_${firstRun}_${lastRun}.cfg
#      cmsRun $cfg_path/mtcc_physics_${firstRun}_${lastRun}.cfg
      exit_status=$?

}

#MAIN

step=$1

#Env Var
export tar_path=/data/mtcc/tars
export runs_path=/data/mtcc/runs
export pedestals_path=/data/mtcc/pedestals
export cfg_path=/data/mtcc/cfg
export fedconnections_path=/data/mtcc/fedconnections
export CMSSW_path=/localscratch/g/giordano/CMSSW/Development/MTCC/CMSSW_0_6_0_pre6/src

cd $CMSSW_path
eval `scramv1 runtime -sh`
cd -

case "$step" in
    "unpack")
#Retrieve RU*.root from tar_path dir and save them in runs_path dir
	unpack
	;;    
"runPedestals")
#run pedestals
	runPedestals
	;;
"runPhysics")
#run pedestals
	runPhysics $2 $3 $4
	;;
	*)
	echo "please explicit a starting step"
esac