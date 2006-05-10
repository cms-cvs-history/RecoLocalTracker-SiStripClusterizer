#!/bin/sh

function unpack(){
    echo -e "&&&&&&&&&&&&&&&&\nUpacking files from $tar_path\n&&&&&&&&&&&&&&&&\n"
    cd $tar_path
    for file in `ls *.tar.gz`
	do
	echo $file
	runNum=`echo $file | sed -e "s#[^0-9]##g"`
	if [ ! -e ${runs_path}/RU[0*]${runNum}*root ];
	    then
	    echo extracting file
	    tar xvzf $file \*RU\*root
	    mv ${runNum}/* $runs_path
	    rm -rf ${runNum}
	fi
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

      #get iov
      iovfirstRun=`echo ${iov[$i]} | awk -F":" '{print $1}'`

      cat $cfg_path/template_mtcc_pedestals.cfg | sed -e "s@insert_fedconnection_description@${fedconnections_path}/${fedconnections}.dat@" | sed -e "s@insert_input_filenames@${inputfilenames}@" | sed -e "s@insert_SiStripPedNoisesDB@${pedestals_path}/SiStripPedNoises.db@" | sed -e "s@insert_SiStripPedNoisesCatalog@${pedestals_path}/SiStripPedNoisesCatalog.xml@" | sed -e "s@insert_iovfirstRun@${iovfirstRun}@g"  | sed -e "s@insert_logpath@${log_path}@g" | sed -e "s@insert_pedRuns@${pedRuns[$i]}@g"> $cfg_path/mtcc_pedestals_${pedRuns[$i]}.cfg

      echo -e "\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
      echo cmsRun $cfg_path/mtcc_pedestals_${pedRuns[$i]}.cfg
      echo -e "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n"
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
    
    grep -v "\#" $output_path/PhysicsRuns_List.dat 
    
    fedconnections=(`grep -v "\#" $output_path/PhysicsRuns_List.dat | awk -F"|" '{print $1}'`)
    Runs=(`grep -v "\#" $output_path/PhysicsRuns_List.dat | awk -F"|" '{print $2}'`)
    
    Ndim=${#Runs[@]}
    
    #loop on entries
    i=0
    while [ $i -lt $Ndim ]
      do
      
      #Create input file list
      firstRun=`echo ${Runs[$i]} | awk -F":" '{print $1}'`
      lastRun=`echo ${Runs[$i]} | awk -F":" '{ if ($2 != "" ) print $2; else print $1}'`
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
      
      cat $cfg_path/template_mtcc_physics.cfg | sed -e "s@insert_fedconnection_description@${fedconnections_path}/${fedconnections}.dat@" | sed -e "s@insert_input_filenames@${inputfilenames}@" | sed -e "s@insert_SiStripPedNoisesDB@${pedestals_path}/SiStripPedNoises.db@" | sed -e "s@insert_SiStripPedNoisesCatalog@${pedestals_path}/SiStripPedNoisesCatalog.xml@" | sed -e "s@insert_outputfilename@${Runs[$i]}@g" | sed -e "s@insert_outputpath@${output_path}@g" | sed -e "s@insert_logpath@${log_path}@g" > $cfg_path/mtcc_physics_${Runs[$i]}.cfg

      echo -e "\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
      echo cmsRun $cfg_path/mtcc_physics_${Runs[$i]}.cfg
      echo -e "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n"
      cmsRun $cfg_path/mtcc_physics_${Runs[$i]}.cfg
      exit_status=$?

      if [ "$exit_status" == "0" ];
	  then
	  cat $output_path/PhysicsRuns_List.dat | sed -re "s@(${fedconnections[$i]}\s*\|\s*${Runs[$i]})@#&@g" >> file.tmp
	  mv -f file.tmp $output_path/PhysicsRuns_List.dat
      else
	  echo -e "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&\nERROR Running Physics on cfg "
	  cat $cfg_path/mtcc_physics_${Runs[$i]}.cfg
	  echo -e "\n&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&\n"

      fi

      let i++
    done
}

function runTestCluster(){
    echo -e "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&\nRunning TestCluster\n&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&\n"

    Run=$1
    file=$output_path/${Run}.root

#Create input file list
    inputfilenames="\"file:${file}\""
    echo $inputfilenames
      
    cat $cfg_path/template_mtcc_TestCluster.cfg | sed -e "s@insert_input_filenames@${inputfilenames}@" | sed -e "s@insert_SiStripPedNoisesDB@${pedestals_path}/SiStripPedNoises.db@" | sed -e "s@insert_SiStripPedNoisesCatalog@${pedestals_path}/SiStripPedNoisesCatalog.xml@" | sed -e "s@insert_outputfilename@TestCluster_${Run}@g" | sed -e "s@insert_outputpath@${test_path}@g" | sed -e "s@insert_logpath@${log_path}@g" > $cfg_path/mtcc_TestCluster_${Run}.cfg

    echo -e "\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo cmsRun $cfg_path/mtcc_TestCluster_${Run}.cfg
    echo -e "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n"
    cmsRun $cfg_path/mtcc_TestCluster_${Run}.cfg
    exit_status=$?
}

#MAIN

step=$1

#Env Var
export workdir=`pwd`
export CMSSW_path=${workdir}/CMSSW/src
export tar_path=${workdir}/tars
export runs_path=${workdir}/runs
export pedestals_path=${workdir}/pedestals
export cfg_path=${workdir}/cfg
export log_path=${workdir}/logs
export fedconnections_path=${workdir}/fedconnections
export output_path=${workdir}/output
export test_path=${workdir}/test

cd $CMSSW_path
eval `scramv1 runtime -sh`
cd -

case "$step" in
    "unpack")
#Retrieve RU*.root from tar_path dir and save them in runs_path dir
	unpack
	;;    
"runPedestals")
	runPedestals
	;;
"runPhysics")
	runPhysics 
	;;
"runTestCluster")
	if [ '`echo $2 | grep -cw "[0-9]*"`' == '1' ]; 
	    then
	    echo -e "\n[usage] :run.sh runTestCluster runNb\n"
	    exit
	fi
	runTestCluster $2
	;;
	*)
	echo "please explicit an analysis step: unpack, runPedestals, runPhysics"
	;;
esac

