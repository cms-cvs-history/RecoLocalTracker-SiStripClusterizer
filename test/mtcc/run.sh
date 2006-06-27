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

function getRunList(){      
#Create input file list
    runList=`echo $1 | sed -e "s#-# #g"`
    inputfilenames=""
    for runs in $runList
      do
      firstRun=`echo ${runs} | awk -F":" '{print $1}'`
      lastRun=`echo ${runs} | awk -F":" '{ if ($2 != "" ) print $2; else print $1}'`
      while [ ${firstRun} -le ${lastRun} ]
	do
	for file in `ls ${runs_path}/RU*${firstRun}*root 2> /dev/null`
	  do
	  [ ! -e $file ] && continue
	  inputfilenames="${inputfilenames},\"file:$file\""
	done
	let firstRun++
      done      
    done
    inputfilenames=`echo $inputfilenames | sed -e "s@,@@"`
    echo $inputfilenames
}

function runPedestals(){
    echo -e "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&\nRunning Pedestals on files in $pedestals_path/PedestalRuns_List.dat\n&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&\n"

    grep -v "\#" $pedestals_path/PedestalRuns_List.dat 

    fedconnections=(`grep -v "\#" $pedestals_path/PedestalRuns_List.dat | awk -F"|" '{print $1}'`)
           pedRuns=(`grep -v "\#" $pedestals_path/PedestalRuns_List.dat | awk -F"|" '{print $2}'`)
    #iov=(`grep -v "\#" $pedestals_path/PedestalRuns_List.dat | awk -F"|" '{print $3}'`)
    
    Ndim=${#pedRuns[@]}

    #loop on entries
    i=0
    while [ $i -lt $Ndim ]
      do

      #Create input file list
      inputfilenames=`getRunList ${pedRuns[$i]}`
      echo $inputfilenames

#       #get iov
      firstRun=`echo ${pedRuns[$i]} | awk -F"-" '{print $1}' | awk -F":" '{print $1}'`
      #iovfirstRun=`echo ${iov[$i]} | awk -F"-" '{print $1}' | awk -F":" '{print $1}'`
      iovfirstRun=$firstRun

      cat $cfg_path/template_mtcc_pedestals.cfg | sed -e "s@insert_fedconnection_description@${fedconnections_path}/${fedconnections[$i]}.dat@" | sed -e "s@insert_input_filenames@${inputfilenames}@" | sed -e "s@insert_SiStripPedNoisesDB@${pedestals_path}/SiStripPedNoises_${iovfirstRun}.db@" | sed -e "s@insert_SiStripPedNoisesCatalog@${pedestals_path}/SiStripPedNoisesCatalog.xml@" | sed -e "s@insert_mappingfileDB@${pedestals_path}/Mapping-custom-1.0.xml@" | sed -e "s@insert_iovfirstRun@${iovfirstRun}@g"  | sed -e "s@insert_logpath@${log_path}@g" | sed -e "s@insert_pedRuns@${firstRun}@g"> $cfg_path/mtcc_pedestals_$firstRun.cfg

      #Remove db file
      [ -e ${pedestals_path}/SiStripPedNoises_${iovfirstRun}.db ] && rm ${pedestals_path}/SiStripPedNoises_${iovfirstRun}.db

      echo -e "\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
      echo cmsRun $cfg_path/mtcc_pedestals_$firstRun.cfg
      echo -e "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n"
      cmsRun $cfg_path/mtcc_pedestals_${firstRun}.cfg
      exit_status=$?
      
      if [ "$exit_status" == "0" ];
 	  then
 	  cat $pedestals_path/PedestalRuns_List.dat | sed -re "s@(${fedconnections[$i]}\s*\|\s*${pedRuns[$i]})@#&@g" >> file.tmp
 	  mv -f file.tmp $pedestals_path/PedestalRuns_List.dat
      else
 	  echo -e "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&\nERROR Running Pedestals on cfg "
 	  cat $cfg_path/mtcc_pedestals_${firstRun}.cfg
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
               iov=(`grep -v "\#" $output_path/PhysicsRuns_List.dat | awk -F"|" '{print $3}'`)
    
    Ndim=${#Runs[@]}
    
    #loop on entries
    i=0
    while [ $i -lt $Ndim ]
      do
      #Create input file list
      inputfilenames=`getRunList ${Runs[$i]}`
      echo $inputfilenames

#       #get iov
      firstRun=`echo ${Runs[$i]} | awk -F"-" '{print $1}' | awk -F":" '{print $1}'`
      iovfirstRun=${iov[$i]}

      cat $cfg_path/template_mtcc_physics.cfg | sed -e "s@insert_fedconnection_description@${fedconnections_path}/${fedconnections[$i]}.dat@" | sed -e "s@insert_input_filenames@${inputfilenames}@" | sed -e "s@insert_SiStripPedNoisesDB@${pedestals_path}/SiStripPedNoises_${iovfirstRun}.db@" | sed -e "s@insert_SiStripPedNoisesCatalog@${pedestals_path}/SiStripPedNoisesCatalog.xml@" | sed -e "s@insert_mappingfileDB@${pedestals_path}/Mapping-custom-1.0.xml@" | sed -e "s@insert_outputfilename@${Runs[$i]}@g" | sed -e "s@insert_outputpath@${output_path}@g" | sed -e "s@insert_logpath@${log_path}@g" > $cfg_path/mtcc_physics_${Runs[$i]}.cfg

      echo -e "\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
      echo cmsRun $cfg_path/mtcc_physics_${Runs[$i]}.cfg
      echo -e "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n"
      cmsRun $cfg_path/mtcc_physics_${Runs[$i]}.cfg
      exit_status=$?

      if [ "$exit_status" == "0" ];
	  then
	  cat $output_path/PhysicsRuns_List.dat | sed -re "s@(${fedconnections[$i]}\s*\|\s*${Runs[$i]}\s*\|\s*${iov[$i]})@#&@g" >> file.tmp
	  mv -f file.tmp $output_path/PhysicsRuns_List.dat
      else
	  echo -e "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&\nERROR Running Physics on cfg "
	  cat $cfg_path/mtcc_physics_${Runs[$i]}.cfg
	  echo -e "\n&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&\n"

      fi

      let i++
    done
}


function runDQM(){
    echo -e "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&\nRunning DQM on files\n&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&\n"
    

    grep -v "\#" $output_path/PhysicsRuns_List.dat

    fedconnections=(`grep -v "\#" $output_path/PhysicsRuns_List.dat | awk -F"|" '{print $1}'`)
              Runs=(`grep -v "\#" $output_path/PhysicsRuns_List.dat | awk -F"|" '{print $2}'`)
               iov=(`grep -v "\#" $output_path/PhysicsRuns_List.dat | awk -F"|" '{print $3}'`)

    
    Ndim=${#Runs[@]}
    
    #loop on entries
    i=0
    while [ $i -lt $Ndim ]
      do
      
      #Create input file list
       inputfilenames=`getRunList ${Runs[$i]}`
      echo $inputfilenames

#       #get iov
      firstRun=`echo ${Runs[$i]} | awk -F"-" '{print $1}' | awk -F":" '{print $1}'`
      iovfirstRun=${iov[$i]}

      cat $cfg_path/template_mtcc_dqm.cfg | sed -e "s@insert_fedconnection_description@${fedconnections_path}/${fedconnections}.dat@" | sed -e "s@insert_input_filenames@${inputfilenames}@" | sed -e "s@insert_SiStripPedNoisesDB@${pedestals_path}/SiStripPedNoises_${iovfirstRun}.db@" | sed -e "s@insert_SiStripPedNoisesCatalog@${pedestals_path}/SiStripPedNoisesCatalog.xml@" | sed -e "s@insert_outputfilename@DQM_${Runs[$i]}@g" | sed -e "s@insert_outputpath@${output_path}@g" | sed -e "s@insert_logpath@${log_path}@g" | sed -e "s@insert_dqmhistos_file@dqm_histos_${Runs[$i]}@g" > $cfg_path/mtcc_dqm_${Runs[$i]}.cfg

      echo -e "\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
      echo cmsRun $cfg_path/mtcc_dqm_${Runs[$i]}.cfg
      echo -e "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n"
      cmsRun $cfg_path/mtcc_dqm_${Runs[$i]}.cfg
      exit_status=$?

      if [ "$exit_status" == "0" ];
	  then
	  cat $output_path/PhysicsRuns_List.dat | sed -re "s@(${fedconnections[$i]}\s*\|\s*${Runs[$i]})@#&@g" >> file.tmp
	  mv -f file.tmp $output_path/DQMRuns_List.dat
      else
	  echo -e "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&\nERROR Running DQM on cfg "
	  cat $cfg_path/mtcc_dqm_${Runs[$i]}.cfg
	  echo -e "\n&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&\n"

      fi

      let i++
    done
}


function runTestCluster(){
    echo -e "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&\nRunning TestCluster\n&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&\n"

    Run=$1
    file=$output_path/${Run}.root

    grep $Run $output_path/PhysicsRuns_List.dat 
    
    iov=(`grep  "${Run}" $output_path/PhysicsRuns_List.dat | awk -F"|" '{print $3}'`)


    iovfirstRun=${iov[0]}

#Create input file list
    inputfilenames="\"file:${file}\""
    echo $inputfilenames
      
    cat $cfg_path/template_mtcc_TestCluster.cfg | sed -e "s@insert_input_filenames@${inputfilenames}@" | sed -e "s@insert_SiStripPedNoisesDB@${pedestals_path}/SiStripPedNoises_${iovfirstRun}.db@" | sed -e "s@insert_SiStripPedNoisesCatalog@${pedestals_path}/SiStripPedNoisesCatalog.xml@" | sed -e "s@insert_outputfilename@TestCluster_${Run}@g" | sed -e "s@insert_mappingfileDB@${pedestals_path}/Mapping-custom-1.0.xml@" | sed -e "s@insert_outputpath@${test_path}@g" | sed -e "s@insert_logpath@${log_path}@g" > $cfg_path/mtcc_TestCluster_${Run}.cfg

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

export CORAL_AUTH_PATH=${pedestals_path}

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
"runDQM")
	runDQM 
	;;
"runTestCluster")
	if [ "$2" == "" ] || [ '`echo $2 | grep -cw "[0-9]*"`' == '1' ]; 
	    then
	    echo -e "\n[usage] :run.sh runTestCluster runNb\n"
	    exit
	fi
	runTestCluster $2
	;;
 	*)
	echo "please explicit an analysis step: unpack, runPedestals, runPhysics, runTestCluster <runNb>,runDQM"
	;;
esac

