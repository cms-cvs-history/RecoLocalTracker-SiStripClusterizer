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
	for file in `ls ${runs_path}/*${firstRun}*root 2> /dev/null`
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
	   mode=(`grep -v "\#" $pedestals_path/PedestalRuns_List.dat | awk -F"|" '{print $3}'| sed -e 's@_GlobalDAQ@@g' -e 's@_LocalDAQ@@g'`)
	   DAQ=(`grep -v "\#" $pedestals_path/PedestalRuns_List.dat | awk -F"|" '{print $3}' | sed -e 's@186_@@g' -e 's@p5_@@g'`)
	   
    
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

      if [ "${mode[$i]}" != "186" ] && [ "${mode[$i]}" != "p5" ]
	  then
	  echo -e "\nPlease explicit in PedestalRuns_List.dat if run is 186_LocalDAQ or p5_LocalDAQ or p5_GlobalDAQ\n"
	  exit
      fi	

      if [ "${DAQ[$i]}" != "LocalDAQ" ] && [ "${DAQ[$i]}" != "GlobalDAQ" ]
	  then
	  echo -e "\nPlease explicit in PedestalsRun_List.dat if run is 186_LocalDAQ or p5_LocalDAQ or p5_GlobalDAQ\n"
	  exit
      fi	

      cat $cfg_path/template_mtcc_pedestals.cfg | sed -e "s@insert_fedconnection_description@${fedconnections_path}/${fedconnections[$i]}.dat@"  -e "s@insert_input_filenames@${inputfilenames}@"  -e "s@insert_SiStripPedNoisesDB@${pedestals_path}/SiStripPedNoises_${iovfirstRun}.db@"  -e "s@insert_SiStripPedNoisesCatalog@${pedestals_path}/SiStripPedNoisesCatalog.xml@"  -e "s@insert_mappingfileDB@${pedestals_path}/Mapping-custom-1.0.xml@"  -e "s@insert_iovfirstRun@${iovfirstRun}@g"   -e "s@insert_logpath@${log_path}@g"  -e "s@insert_pedRuns@${firstRun}@g"  -e "s@##${mode[$i]}@@g" -e "s@##${DAQ[$i]}@@g" > $cfg_path/mtcc_pedestals_$firstRun.cfg

      #Remove db file
      [ -e ${pedestals_path}/SiStripPedNoises_${iovfirstRun}.db ] && rm ${pedestals_path}/SiStripPedNoises_${iovfirstRun}.db

      #Create new db file
      echo -e "\n...Creating new db file, following custom mapping"
      echo -e "pool_build_object_relational_mapping -f ${pedestals_path}/Mapping-custom-1.0.xml -d CondFormatsSiStripObjects -c sqlite_file:${pedestals_path}/SiStripPedNoises_${iovfirstRun}.db -u me -p mypass"
      pool_build_object_relational_mapping -f ${pedestals_path}/Mapping-custom-1.0.xml -d CondFormatsSiStripObjects -c sqlite_file:${pedestals_path}/SiStripPedNoises_${iovfirstRun}.db  -u me -p mypass

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
	      mode=(`grep -v "\#" $output_path/PhysicsRuns_List.dat | awk -F"|" '{print $4}'| sed -e 's@_GlobalDAQ@@g' -e 's@_LocalDAQ@@g'`)
	       DAQ=(`grep -v "\#" $output_path/PhysicsRuns_List.dat | awk -F"|" '{print $4}' | sed -e 's@186_@@g' -e 's@p5_@@g'`)
    
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

      if [ "${mode[$i]}" != "186" ] && [ "${mode[$i]}" != "p5" ]
	  then
	  echo -e "\nPlease explicit in PhysicsRuns_List.dat if run is 186_LocalDAQ or p5_LocalDAQ or p5_GlobalDAQ\n"
	  exit
      fi	

      if [ "${DAQ[$i]}" != "LocalDAQ" ] && [ "${DAQ[$i]}" != "GlobalDAQ" ]
	  then
	  echo -e "\nPlease explicit in PhysicsRuns_List.dat if run is 186_LocalDAQ or p5_LocalDAQ or p5_GlobalDAQ\n"
	  exit
      fi	

      cat $cfg_path/template_mtcc_physics.cfg | sed -e "s@insert_fedconnection_description@${fedconnections_path}/${fedconnections[$i]}.dat@"  -e "s@insert_input_filenames@${inputfilenames}@"  -e "s@insert_SiStripPedNoisesDB@${pedestals_path}/SiStripPedNoises_${iovfirstRun}.db@"  -e "s@insert_SiStripPedNoisesCatalog@${pedestals_path}/SiStripPedNoisesCatalog.xml@"  -e "s@insert_mappingfileDB@${pedestals_path}/Mapping-custom-1.0.xml@"  -e "s@insert_outputfilename@${firstRun}@g"  -e "s@insert_outputpath@${output_path}@g"  -e "s@insert_logpath@${log_path}@g" -e "s@##${mode[$i]}@@g" -e "s@##${DAQ[$i]}@@g" > $cfg_path/mtcc_physics_${Runs[$i]}.cfg

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
	      mode=(`grep -v "\#" $output_path/PhysicsRuns_List.dat | awk -F"|" '{print $4}'| sed -e 's@_GlobalDAQ@@g' -e 's@_LocalDAQ@@g'`)
	       DAQ=(`grep -v "\#" $output_path/PhysicsRuns_List.dat | awk -F"|" '{print $4}' | sed -e 's@186_@@g' -e 's@p5_@@g'`)

    
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

      if [ "${mode[$i]}" != "186" ] && [ "${mode[$i]}" != "p5" ]
	  then
	  echo -e "\nPlease explicit in PhysicsRuns_List.dat if run is 186_LocalDAQ or p5_LocalDAQ or p5_GlobalDAQ\n"
	  exit
      fi	

      if [ "${DAQ[$i]}" != "LocalDAQ" ] && [ "${DAQ[$i]}" != "GlobalDAQ" ]
	  then
	  echo -e "\nPlease explicit in PhysicsRuns_List.dat if run is 186_LocalDAQ or p5_LocalDAQ or p5_GlobalDAQ\n"
	  exit
      fi	

      cat $cfg_path/template_mtcc_dqm.cfg | sed -e "s@insert_fedconnection_description@${fedconnections_path}/${fedconnections}.dat@"  -e "s@insert_input_filenames@${inputfilenames}@"  -e "s@insert_SiStripPedNoisesDB@${pedestals_path}/SiStripPedNoises_${iovfirstRun}.db@"  -e "s@insert_SiStripPedNoisesCatalog@${pedestals_path}/SiStripPedNoisesCatalog.xml@"  -e "s@insert_outputfilename@DQM_${Runs[$i]}@g"  -e "s@insert_outputpath@${output_path}@g"  -e "s@insert_logpath@${log_path}@g"  -e "s@insert_dqmhistos_file@dqm_histos_${firstRun}@g" -e "s@##${mode[$i]}@@g" -e "s@##${DAQ[$i]}@@g" > $cfg_path/mtcc_dqm_${Runs[$i]}.cfg

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
      
    cat $cfg_path/template_mtcc_TestCluster.cfg | sed -e "s@insert_input_filenames@${inputfilenames}@"  -e "s@insert_SiStripPedNoisesDB@${pedestals_path}/SiStripPedNoises_${iovfirstRun}.db@"  -e "s@insert_SiStripPedNoisesCatalog@${pedestals_path}/SiStripPedNoisesCatalog.xml@"  -e "s@insert_outputfilename@TestCluster_${Run}@g"  -e "s@insert_mappingfileDB@${pedestals_path}/Mapping-custom-1.0.xml@"  -e "s@insert_outputpath@${test_path}@g"  -e "s@insert_logpath@${log_path}@g" > $cfg_path/mtcc_TestCluster_${Run}.cfg

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
export CORAL_AUTH_USER=me
export CORAL_AUTH_PASSWORD=me


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

