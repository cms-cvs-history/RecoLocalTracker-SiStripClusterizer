#include "FWCore/PluginManager/interface/ModuleDef.h"
#include "FWCore/Framework/interface/MakerMacros.h"

DEFINE_SEAL_MODULE();

#include "RecoLocalTracker/SiStripClusterizer/test/plugins/SiStripClusterValidator.h"
DEFINE_ANOTHER_FWK_MODULE(SiStripClusterValidator);

