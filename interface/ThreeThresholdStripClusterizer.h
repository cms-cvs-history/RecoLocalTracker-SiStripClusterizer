#ifndef RECOLOCALTRACKER_SISTRIPCLUSTERIZER_THREETHRESHOLDSTRIPCLUSTERIZER_H
#define RECOLOCALTRACKER_SISTRIPCLUSTERIZER_THREETHRESHOLDSTRIPCLUSTERIZER_H

//Data Formats
#include "DataFormats/Common/interface/DetSetVector.h"
#include "DataFormats/SiStripDigi/interface/SiStripDigi.h"
#include "DataFormats/SiStripCluster/interface/SiStripCluster.h"
#include "FWCore/MessageLogger/interface/MessageLogger.h"

//SiStripNoiseService
#include "CommonTools/SiStripZeroSuppression/interface/SiStripNoiseService.h"

#include <vector>
#include <algorithm>
#include <cmath>


class ThreeThresholdStripClusterizer {
public:

  ThreeThresholdStripClusterizer(float strip_thr, float seed_thr,float clust_thr, int max_holes) :
    theChannelThreshold(strip_thr), 
    theSeedThreshold(seed_thr),
    theClusterThreshold(clust_thr),
    max_holes_(max_holes){};
 
  void setSiStripNoiseService( SiStripNoiseService* in ){ SiStripNoiseService_=in;}

  void clusterizeDetUnit(const edm::DetSet<SiStripDigi>&,edm::DetSet<SiStripCluster>&);

  float channelThresholdInNoiseSigma() const { return theChannelThreshold;}
  float seedThresholdInNoiseSigma()    const { return theSeedThreshold;}
  float clusterThresholdInNoiseSigma() const { return theClusterThreshold;}

private:
  SiStripNoiseService* SiStripNoiseService_; 

  float theChannelThreshold;
  float theSeedThreshold;
  float theClusterThreshold;
  int max_holes_;

};

class AboveSeed {
 public:
  AboveSeed(float aseed,SiStripNoiseService* noise,const uint32_t& detID) : seed(aseed), noise_(noise),detID_(detID) {};
  inline bool operator()(const SiStripDigi& digi) { 
    return ( 
	    !noise_->getDisable(detID_,digi.strip()) 
	    && 
	    digi.adc() >= seed * noise_->getNoise(detID_,digi.strip())
	    );
  }
private:
  float seed;
  SiStripNoiseService* noise_;
  const uint32_t& detID_;
};

#endif
