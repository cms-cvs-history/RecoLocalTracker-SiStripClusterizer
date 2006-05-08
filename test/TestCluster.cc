#include "RecoLocalTracker/SiStripClusterizer/test/TestCluster.h"

namespace cms{
  TestCluster::TestCluster(edm::ParameterSet const& conf): 
    conf_(conf),
    filename_(conf.getParameter<std::string>("fileName")), 
    SiStripNoiseService_(conf),
    SiStripPedestalsService_(conf)
  {};

  TestCluster::~TestCluster(){};
  
  void TestCluster::beginJob( const edm::EventSetup& es ) {
    char name[128];
    
    SiStripNoiseService_.configure(es);
    SiStripPedestalsService_.configure(es);
    
    myFile = new TFile(filename_.c_str(),"RECREATE");
    myFile->cd();    
    //get geom    
    es.get<TrackerDigiGeometryRecord>().get( tkgeom );
    edm::LogInfo("TestCluster") << "[TestCluster::beginJob] There are "<<tkgeom->dets().size() <<" detectors instantiated in the geometry" << std::endl;  
    

    edm::ParameterSet Parameters;
    for(TrackerGeometry::DetContainer::const_iterator it = tkgeom->dets().begin(); it != tkgeom->dets().end(); it++){           
      uint32_t detid=((*it)->geographicalId()).rawId();       
      
      const StripGeomDetUnit* _StripGeomDetUnit = dynamic_cast<const StripGeomDetUnit*>(tkgeom->idToDetUnit(DetId(detid)));
      if (_StripGeomDetUnit==0){
	edm::LogError("TestCluster")<< "[TestCluster::beginJob] the detID " << detid << " doesn't seem to belong to Tracker" << std::endl; 
	continue;
      }

      sprintf(name,"ClusterSignal_%s_%d",_StripGeomDetUnit->type().name().c_str(),detid);    
      edm::LogInfo("TestCluster") << "[TestCluster::beginJob] histo name" << name; 
      Parameters =  conf_.getParameter<edm::ParameterSet>("TH1ClusterSignal");
      _TH1F_ClusterSignal_m[detid] = new TH1F(name,name,
					      Parameters.getParameter<int32_t>("Nbinx"),
					      Parameters.getParameter<double>("xmin"),
					      Parameters.getParameter<double>("xmax")
					      );

      sprintf(name,"ClusterStoN_%s_%d",_StripGeomDetUnit->type().name().c_str(),detid);
      Parameters =  conf_.getParameter<edm::ParameterSet>("TH1ClusterStoN");
      _TH1F_ClusterStoN_m[detid] = new TH1F(name,name,
					    Parameters.getParameter<int32_t>("Nbinx"),
					    Parameters.getParameter<double>("xmin"),
					    Parameters.getParameter<double>("xmax")
					    );

      sprintf(name,"PedestalsProfile_%s_%d",_StripGeomDetUnit->type().name().c_str(),detid);
      Parameters =  conf_.getParameter<edm::ParameterSet>("TH1PedestalsProfile");
      _TH1F_PedestalsProfile_m[detid] = new TH1F(name,name,
						 Parameters.getParameter<int32_t>("Nbinx"),
						 Parameters.getParameter<double>("xmin"),
						 Parameters.getParameter<double>("xmax")
						 );

      sprintf(name,"NoisesProfile_%s_%d",_StripGeomDetUnit->type().name().c_str(),detid);
      Parameters =  conf_.getParameter<edm::ParameterSet>("TH1NoisesProfile");
      _TH1F_NoisesProfile_m[detid] = new TH1F(name,name,
					      Parameters.getParameter<int32_t>("Nbinx"),
					      Parameters.getParameter<double>("xmin"),
					      Parameters.getParameter<double>("xmax")
					      );
    }

    std::string SubDet[3]={"TIB","TOB","TEC"};
    for (int i=0;i<3;i++){
      sprintf(name,"ClusterSignal_Cumulative_%s",SubDet[i].c_str());
      Parameters =  conf_.getParameter<edm::ParameterSet>("TH1ClusterSignal");
      _TH1F_ClusterSignal_v.push_back(new TH1F(name,name,
					Parameters.getParameter<int32_t>("Nbinx"),
					Parameters.getParameter<double>("xmin"),
					Parameters.getParameter<double>("xmax")
					)
			       );
      sprintf(name,"ClusterStoN_Cumulative_%s",SubDet[i].c_str());
      Parameters =  conf_.getParameter<edm::ParameterSet>("TH1ClusterStoN");
      _TH1F_ClusterStoN_v.push_back(new TH1F(name,name,
					     Parameters.getParameter<int32_t>("Nbinx"),
					     Parameters.getParameter<double>("xmin"),
					     Parameters.getParameter<double>("xmax")
					     )
				    );
      sprintf(name,"Noises_Cumulative_%s",SubDet[i].c_str());
      Parameters =  conf_.getParameter<edm::ParameterSet>("TH1Noises");
      _TH1F_Noises_v.push_back(new TH1F(name,name,
					Parameters.getParameter<int32_t>("Nbinx"),
					Parameters.getParameter<double>("xmin"),
					Parameters.getParameter<double>("xmax")
					)
			       );
    }
  }

  void TestCluster::endJob() {  
    edm::LogInfo("TestCluster") << "[TestCluster::endJob] >>> ending histograms" << std::endl;

    myFile->cd();

    for(TrackerGeometry::DetContainer::const_iterator it = tkgeom->dets().begin(); it != tkgeom->dets().end(); it++){           

      //Get DetID
      uint32_t detid=((*it)->geographicalId()).rawId();    
      
      int numStrips;
      
      //Get numStrips and verify that detid belongs to tracker
      const StripGeomDetUnit*_StripGeomDetUnit = dynamic_cast<const StripGeomDetUnit*>(tkgeom->idToDetUnit(DetId(detid)));
      if (_StripGeomDetUnit==0)
	continue;
      else{
	numStrips = _StripGeomDetUnit->specificTopology().nstrips(); // det module number of strips
      }

      edm::LogInfo("TestCluster") << "[TestCluster::endJob] Nstrip for detID " << detid << " of name " <<  _StripGeomDetUnit->type().name().c_str() << " is " << numStrips;

      for (int istrip=0;istrip<numStrips;istrip++){

	try{
	  //Fill Pedestals
	  edm::LogInfo("TestCluster") << "[TestCluster::endJob] Fill Ped detid " << detid << " strip " << istrip;
	  _TH1F_PedestalsProfile_m.find(detid)->second->Fill(istrip,SiStripPedestalsService_.getPedestal(detid,istrip));
	  //Fill Noises
	  edm::LogInfo("TestCluster") << "[TestCluster::endJob] Fill Noise detid " << detid << " strip " << istrip;
	  _TH1F_NoisesProfile_m.find(detid)->second->Fill(istrip,SiStripNoiseService_.getNoise(detid,istrip));
	  
	  int iSubDet=_StripGeomDetUnit->specificType().subDetector()-1;
	  _TH1F_Noises_v[iSubDet]->Fill(SiStripNoiseService_.getNoise(detid,istrip));
	  //check
	  if (SiStripNoiseService_.getNoise(detid,istrip) != SiStripPedestalsService_.getNoise(detid,istrip)) {
	    edm::LogError("TestCluster") << "[TestCluster::endJob]  ERROR for detid " 
					 << detid << " strip " << istrip 
					 << "SiStripNoise and SiStripPedestal are different " 
					 << SiStripNoiseService_.getNoise(detid,istrip) << " " 
					 << SiStripPedestalsService_.getNoise(detid,istrip);
	  }	
	}
	catch(cms::Exception& e){
	  edm::LogError("TestCluster") << "[TestCluster::endJob]  cms::Exception:  DetName " << _StripGeomDetUnit->type().name() << " " << e.what() ;
	}
      }
      edm::LogInfo("TestCluster") << "[TestCluster::endJob]  prima di remove";
      //
      //Remove det with low entries
      {
	std::map<uint32_t,TH1F*>::iterator hiter = _TH1F_ClusterSignal_m.find(detid);
	if (hiter->second->GetMean()==0 || hiter->second->GetEntries() < 200){
	  edm::LogError("TestCluster") << "[TestCluster::endJob]  " 
				       << "il det " << hiter->first 
				       << " non ha entries con media maggiore di zero || entries > 200";
	  delete hiter->second;
	  _TH1F_ClusterSignal_m.erase(hiter);
	}
      }
      {
	std::map<uint32_t,TH1F*>::iterator hiter = _TH1F_ClusterStoN_m.find(detid);
	if (hiter->second->GetMean()==0 || hiter->second->GetEntries() < 200){
	  edm::LogError("TestCluster") << "[TestCluster::endJob]  " 
				       << "il det " << hiter->first 
				       << " non ha entries con media maggiore di zero || entries > 200";
	  delete hiter->second;
	  _TH1F_ClusterStoN_m.erase(hiter);
	}
      }
      {
	std::map<uint32_t,TH1F*>::iterator hiter = _TH1F_PedestalsProfile_m.find(detid);
	if (hiter->second->GetEntries() == 0){
	  edm::LogError("TestCluster") << "[TestCluster::endJob]  " 
				       << "il det " << hiter->first 
				       << " non ha entries con media maggiore di zero || entries > 200";
	  delete hiter->second;
	  _TH1F_PedestalsProfile_m.erase(hiter);
	}
      }
      {
	std::map<uint32_t,TH1F*>::iterator hiter = _TH1F_NoisesProfile_m.find(detid);
	if (hiter->second->GetEntries() == 0){
	  edm::LogError("TestCluster") << "[TestCluster::endJob]  " 
				       << "il det " << hiter->first 
				       << " non ha entries con media maggiore di zero || entries > 200";
	  delete hiter->second;
	  _TH1F_NoisesProfile_m.erase(hiter);
	}
      }      
    }

    myFile->ls();
    myFile->Write();
    myFile->Close();
  }

  void TestCluster::analyze(const edm::Event& e, const edm::EventSetup& es) {
    edm::LogInfo("TestCluster") << "[TestCluster::analyse]  " << "Run " << e.id().run() << " Event " << e.id().event() << std::endl;
    
    edm::Handle< edm::DetSetVector<SiStripCluster> >  input;
    e.getByLabel("ThreeThresholdClusterizer",input);
    
    //Loop on Dets
    edm::DetSetVector<SiStripCluster>::const_iterator DSViter=input->begin();
    for (; DSViter!=input->end();DSViter++){
      uint32_t detid = DSViter->id;
      const StripGeomDetUnit*_StripGeomDetUnit = dynamic_cast<const StripGeomDetUnit*>(tkgeom->idToDetUnit(DetId(detid)));
      
      float clusiz=0;      
      //Loop on Clusters
      for(edm::DetSet<SiStripCluster>::const_iterator ic = DSViter->data.begin(); ic!=DSViter->data.end(); ic++) {

	clusiz = ic->amplitudes().size();
	int barycenter=((int)ic->barycenter())%128;
	float Signal=0;
	float noise2=0;
	int count=0;
	
	//	if ( barycenter>3 && barycenter<125)
	{
	  const std::vector<short> amplitudes=ic->amplitudes();
	  for(size_t i=0; i<amplitudes.size();i++)
	    if (amplitudes[i]>0){
	      Signal+=amplitudes[i];
	      noise2+=SiStripNoiseService_.getNoise(detid,ic->firstStrip()+i)*SiStripNoiseService_.getNoise(detid,ic->firstStrip()+i);
	      count++;
	    }
	  //Fill Histos
	  _TH1F_ClusterSignal_m.find(detid)->second->Fill(Signal);
	  _TH1F_ClusterStoN_m.find(detid)->second->Fill(Signal/sqrt(noise2/count));
	  
	  int iSubDet=_StripGeomDetUnit->specificType().subDetector()-1;
	  _TH1F_ClusterSignal_v[iSubDet]->Fill(Signal);
	  _TH1F_ClusterStoN_v[iSubDet]->Fill(Signal/sqrt(noise2/count));
	}
      }
    }
  }
}

