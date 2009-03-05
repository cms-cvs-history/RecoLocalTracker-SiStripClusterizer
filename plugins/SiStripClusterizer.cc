#include "RecoLocalTracker/SiStripClusterizer/plugins/SiStripClusterizer.h"

#include "FWCore/Framework/interface/Event.h"
#include "FWCore/Framework/interface/EventSetup.h"
#include "FWCore/MessageLogger/interface/MessageLogger.h"
#include "FWCore/ParameterSet/interface/ParameterSet.h"
#include "FWCore/ParameterSet/interface/InputTag.h"

#include "DataFormats/Common/interface/Handle.h"
#include "DataFormats/Common/interface/DetSetVector.h"
#include "DataFormats/Common/interface/DetSetVectorNew.h"
#include "DataFormats/SiStripDigi/interface/SiStripDigi.h"
#include "DataFormats/SiStripCluster/interface/SiStripCluster.h"

#include "RecoLocalTracker/SiStripClusterizer/interface/StripClusterizerAlgorithmFactory.h"
#include "RecoLocalTracker/SiStripClusterizer/interface/StripClusterizerAlgorithm.h"

SiStripClusterizer::
SiStripClusterizer(const edm::ParameterSet& conf) 
  : inputTags( conf.getParameter<std::vector<edm::InputTag> >("DigiProducersList") ),
    algorithm( StripClusterizerAlgorithmFactory::create(conf) ) {
  produces< edmNew::DetSetVector<SiStripCluster> > ();
}

void SiStripClusterizer::
produce(edm::Event& event, const edm::EventSetup& es)  {

  std::auto_ptr< edmNew::DetSetVector<SiStripCluster> > output(new edmNew::DetSetVector<SiStripCluster>());
  output->reserve(10000,4*10000); //(moduleIDs,clusters) FIXME: should be optimized considering expected occupancy

  edm::Handle< edm::DetSetVector<SiStripDigi> >     inputOld;  
  edm::Handle< edmNew::DetSetVector<SiStripDigi> >  inputNew;  

  algorithm->initialize(es);  
  if( findInput(inputOld, event) ) algorithm->clusterize(*inputOld, *output); else 
    if( findInput(inputNew, event) ) algorithm->clusterize(*inputNew, *output); else
      edm::LogError("[SiStripClusterizer] Input Not Found");

  edm::LogInfo("[SiStripClusterizer] Product: ") << output->dataSize() << " clusters from " 
						 << output->size()     << " detector modules";
  event.put(output);
}

template<class T>
inline
bool SiStripClusterizer::
findInput(edm::Handle<T>& handle, const edm::Event& e) {

  for(std::vector<edm::InputTag>::const_iterator 
	inputTag = inputTags.begin();  inputTag != inputTags.end();  inputTag++) {

    e.getByLabel(*inputTag, handle);
    if( handle.isValid() && !handle->empty() ) {
      edm::LogInfo("[SiStripClusterizer] Input from ") << *inputTag;
      return true;
    }
  }
  return false;
}
