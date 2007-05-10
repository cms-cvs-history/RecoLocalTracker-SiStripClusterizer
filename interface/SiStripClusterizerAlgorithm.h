#ifndef SiStripClusterizerAlgorithm_h
#define SiStripClusterizerAlgorithm_h

/** \class SiStripClusterizerAlgorithm
 *
 * SiStripClusterizerAlgorithm invokes specific strip clustering algorithms
 *
 * \author Oliver Gutsche, Fermilab
 *
 * \version   1st Version Aug. 1, 2005
 *
 ************************************************************/

//edm
#include "DataFormats/Common/interface/Handle.h"
#include "FWCore/Framework/interface/ESHandle.h"
#include "FWCore/ParameterSet/interface/ParameterSet.h"
#include "FWCore/MessageLogger/interface/MessageLogger.h"
//Data Formats
#include "DataFormats/Common/interface/DetSet.h"
#include "DataFormats/SiStripDigi/interface/SiStripDigi.h"
#include "DataFormats/SiStripCluster/interface/SiStripCluster.h"
//Algorithm
#include "RecoLocalTracker/SiStripClusterizer/interface/ThreeThresholdStripClusterizer.h"
#include "CalibFormats/SiStripObjects/interface/SiStripGain.h"

#include <iostream> 
#include <memory>
#include <string>
#include <vector>


class SiStripClusterizerAlgorithm 
{
 public:
  
  SiStripClusterizerAlgorithm(const edm::ParameterSet& conf);
  ~SiStripClusterizerAlgorithm();

  /// Runs the algorithm
  void run(const edm::DetSetVector<SiStripDigi>& input,std::vector< 
edm::DetSet<SiStripCluster> >& output, const edm::ESHandle<SiStripGain> 
& gainHandle);

  void configure( SiStripNoiseService* );

 private:
  edm::ParameterSet conf_;
  ThreeThresholdStripClusterizer* ThreeThresholdStripClusterizer_;
  std::string clusterMode_;
  bool validClusterizer_;
};

#endif
