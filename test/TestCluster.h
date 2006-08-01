#ifndef TestCluster_h
#define TestCluster_h

#include "FWCore/Utilities/interface/Exception.h"
#include "FWCore/Framework/interface/EDAnalyzer.h"
#include "FWCore/Framework/interface/Event.h"
#include "FWCore/Framework/interface/Handle.h"
#include "FWCore/Framework/interface/EventSetup.h"
#include "FWCore/Framework/interface/ESHandle.h"
#include "FWCore/Framework/interface/Frameworkfwd.h"
#include "FWCore/Framework/interface/MakerMacros.h" 
#include "FWCore/ParameterSet/interface/ParameterSet.h"

#include "Geometry/TrackerGeometryBuilder/interface/TrackerGeometry.h"  
#include "Geometry/Records/interface/TrackerDigiGeometryRecord.h"
#include "Geometry/CommonDetUnit/interface/GeomDetUnit.h"
#include "Geometry/TrackerGeometryBuilder/interface/StripGeomDetUnit.h"
#include "Geometry/CommonTopologies/interface/StripTopology.h"
#include "Geometry/CommonDetUnit/interface/GeomDetType.h"
//needed for the geometry:
#include "DataFormats/DetId/interface/DetId.h"
#include "DataFormats/SiStripDetId/interface/StripSubdetector.h"
#include "DataFormats/SiStripDetId/interface/TECDetId.h"
#include "DataFormats/SiStripDetId/interface/TIBDetId.h"
#include "DataFormats/SiStripDetId/interface/TIDDetId.h"
#include "DataFormats/SiStripDetId/interface/TOBDetId.h"

//Data Formats
#include "DataFormats/Common/interface/DetSetVector.h"
#include "DataFormats/SiStripDigi/interface/SiStripDigi.h"
#include "DataFormats/SiStripCluster/interface/SiStripCluster.h"

//SiStripPedestalsService
#include "RecoLocalTracker/SiStripZeroSuppression/interface/SiStripPedestalsService.h"
#include "RecoLocalTracker/SiStripClusterizer/interface/SiStripNoiseService.h"
#include "FWCore/ParameterSet/interface/InputTag.h"

#include "TROOT.h"
#include "TFile.h"
#include "TTree.h"
#include "TBranch.h"
#include "TH1F.h"
#include "TH2F.h"
#include "TString.h"

#include "vector"
#include <memory>
#include <string>
#include <iostream>

//#include "ClusterTree.h"

namespace cms{
  class TestCluster : public edm::EDAnalyzer
    {
    public:
      
      TestCluster(const edm::ParameterSet& conf);
  
      ~TestCluster();
      
      void beginJob( const edm::EventSetup& es );
      
      void endJob();
      
      void analyze(const edm::Event& e, const edm::EventSetup& c);
  
    private:
  
      edm::ParameterSet conf_;
      const StripTopology* topol;
      edm::ESHandle<TrackerGeometry> tkgeom;
      std::map< uint32_t, TH1F* >  _TH1F_ClusterSignal_m;
      std::map< uint32_t, TH1F* >  _TH1F_ClusterStoN_m;
      std::map< uint32_t, TH1F* >  _TH1F_ClusterBarycenter_m;
      std::map< uint32_t, TH1F* >  _TH1F_PedestalsProfile_m;
      std::map< uint32_t, TH1F* >  _TH1F_NoisesProfile_m;
      std::map< uint32_t, TH1F* >  _TH1F_BadStripNoiseProfile_m;
      std::vector<TH1F*> _TH1F_Noises_v;
      std::vector<TH1F*> _TH1F_ClusterSignal_v;
      std::vector<TH1F*> _TH1F_ClusterStoN_v;
      std::string filename_;
      TFile* fFile;
/*       TTree* fTree; */
/*       TTree* fTree2; */

/*       ClusterEvent* ClusterEvent_; */

      int runNb;
      int eventNb;

      SiStripNoiseService SiStripNoiseService_;  
      SiStripPedestalsService SiStripPedestalsService_;  
      edm::InputTag src_;
    };
}
#endif
