#ifndef SiStripClusterizer_h
#define SiStripClusterizer_h

/** \class SiStripClusterizer
 *
 * SiStripClusterizer is the EDProducer subclass which clusters
 * SiStripDigi/interface/StripDigi.h to SiStripCluster/interface/SiStripCluster.h
 *
 * \author Oliver Gutsche, Fermilab
 *
 * \version   1st Version Aug. 01, 2005  

 *
 ************************************************************/

//edm
#include "FWCore/Framework/interface/EDProducer.h"
#include "FWCore/Framework/interface/Event.h"
#include "FWCore/Framework/interface/EventSetup.h"
#include "FWCore/Framework/interface/Handle.h"
#include "FWCore/Framework/interface/ESHandle.h"
#include "FWCore/ParameterSet/interface/ParameterSet.h"
#include "FWCore/MessageLogger/interface/MessageLogger.h"
//Data Formats
#include "DataFormats/Common/interface/DetSetVector.h"
#include "DataFormats/Common/interface/DetSet.h"
#include "DataFormats/SiStripDigi/interface/SiStripDigi.h"
#include "DataFormats/SiStripDigi/interface/SiStripRawDigi.h"
//Clusterizer
#include "RecoLocalTracker/SiStripClusterizer/interface/SiStripClusterizerAlgorithm.h"
//SiStripPedestalsService
#include "CommonTools/SiStripZeroSuppression/interface/SiStripNoiseService.h"

#include <iostream> 
#include <memory>
#include <string>


namespace cms
{
  class SiStripClusterizer : public edm::EDProducer
  {
  public:

    explicit SiStripClusterizer(const edm::ParameterSet& conf);

    virtual ~SiStripClusterizer();

    virtual void beginJob( const edm::EventSetup& );

    virtual void produce(edm::Event& e, const edm::EventSetup& c);

  private:
    edm::ParameterSet conf_;
    SiStripClusterizerAlgorithm SiStripClusterizerAlgorithm_;
    SiStripNoiseService SiStripNoiseService_;  
  };
}
#endif
