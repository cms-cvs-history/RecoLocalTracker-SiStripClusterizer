#include "RecoLocalTracker/SiStripClusterizer/interface/StripClusterizerAlgorithmFactory.h"

#include "FWCore/ParameterSet/interface/ParameterSet.h"
#include "RecoLocalTracker/SiStripClusterizer/interface/StripClusterizerAlgorithm.h"
#include "RecoLocalTracker/SiStripClusterizer/interface/ThreeThresholdAlgorithm.h"

std::auto_ptr<StripClusterizerAlgorithm> StripClusterizerAlgorithmFactory::
create(const edm::ParameterSet& conf) {
  std::string algorithm = conf.getParameter<std::string>("Algorithm");

  if(algorithm == "ThreeThresholdAlgorithm") {
    return std::auto_ptr<StripClusterizerAlgorithm>(
	   new ThreeThresholdAlgorithm(
	       conf.getParameter<double>("ChannelThreshold"),
	       conf.getParameter<double>("SeedThreshold"),
	       conf.getParameter<double>("ClusterThreshold"),
	       conf.getParameter<unsigned>("MaxSequentialHoles"),
	       conf.getParameter<unsigned>("MaxSequentialBad"),
	       conf.getParameter<unsigned>("MaxAdjacentBad") ));
  }

  throw cms::Exception("[StripClusterizerAlgorithmFactory] Unregistered Algorithm")
    << algorithm << " is not a registered StripClusterizerAlgorithm";
}
