#!/bin/sh

Release=CMSSW_0_6_0_pre6

cmscvsroot CMSSW
echo "anonymous login: when prompted for the CVS password, type '98passwd' "
cvs login

scramv1 project CMSSW $Release
cd $Release/src
cvs co -r V02-00-01 RecoLocalTracker/SiStripClusterizer
cvs co -r V00-00-06 DataFormats/SiStripCluster
