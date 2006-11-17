#include "RecoLocalTracker/SiStripClusterizer/test/TestCluster.h"

namespace cms{
  TestCluster::TestCluster(edm::ParameterSet const& conf): 
    conf_(conf),
    filename_(conf.getParameter<std::string>("fileName")), 
    SiStripNoiseService_(conf),
    SiStripPedestalsService_(conf),
    src_( conf.getParameter<edm::InputTag>( "src" ) )
  {}

  TestCluster::~TestCluster(){}
  
  void TestCluster::beginJob( const edm::EventSetup& es ) {
    char name[128];
    
    fFile = new TFile(filename_.c_str(),"RECREATE");
    fFile->mkdir("Pedestals");
    fFile->mkdir("Noises");
    fFile->mkdir("BadStrips");
    fFile->mkdir("ClusterSignal");
    fFile->mkdir("ClusterStoN");
    fFile->mkdir("ClusterBarycenter");

    fFile->cd();
    
//     fTree  = new TTree("Clusters","Clusters for Detector");

//     ClusterEvent_ = new ClusterEvent;

//     fTree->Branch("runNb", &runNb,"runNb/I");
//     fTree->Branch("eventNb", &eventNb,"eventNb/I");
//     fTree->Branch("event","ClusterEvent",&ClusterEvent_,8000,2);

    //Create histograms

    //get geom    
    es.get<TrackerDigiGeometryRecord>().get( tkgeom );
    edm::LogInfo("TestCluster") << "[TestCluster::beginJob] There are "<<tkgeom->detUnits().size() <<" detectors instantiated in the geometry" << std::endl;  
    
    edm::ParameterSet Parameters;
    for(TrackerGeometry::DetUnitContainer::const_iterator it = tkgeom->detUnits().begin(); it != tkgeom->detUnits().end(); it++){           
      uint32_t detid=((*it)->geographicalId()).rawId();       
      
      const StripGeomDetUnit* _StripGeomDetUnit = dynamic_cast<const StripGeomDetUnit*>(tkgeom->idToDetUnit(DetId(detid)));
      if (_StripGeomDetUnit==0){
	edm::LogError("TestCluster")<< "[TestCluster::beginJob] the detID " << detid << " doesn't seem to belong to Tracker" << std::endl; 
	continue;
      }

      sprintf(name,"ClusterSignal_%s_%d",_StripGeomDetUnit->type().name().c_str(),detid);    
      Parameters =  conf_.getParameter<edm::ParameterSet>("TH1ClusterSignal");
      fFile->cd();fFile->cd("ClusterSignal");
      _TH1F_ClusterSignal_m[detid] = new TH1F(name,name,
					      Parameters.getParameter<int32_t>("Nbinx"),
					      Parameters.getParameter<double>("xmin"),
					      Parameters.getParameter<double>("xmax")
					      );

      sprintf(name,"ClusterStoN_%s_%d",_StripGeomDetUnit->type().name().c_str(),detid);
      Parameters =  conf_.getParameter<edm::ParameterSet>("TH1ClusterStoN");
      fFile->cd();fFile->cd("ClusterStoN");
      _TH1F_ClusterStoN_m[detid] = new TH1F(name,name,
					    Parameters.getParameter<int32_t>("Nbinx"),
					    Parameters.getParameter<double>("xmin"),
					    Parameters.getParameter<double>("xmax")
					    );

      sprintf(name,"ClusterBarycenter_%s_%d",_StripGeomDetUnit->type().name().c_str(),detid);
      Parameters =  conf_.getParameter<edm::ParameterSet>("TH1ClusterBarycenter");
      fFile->cd();fFile->cd("ClusterBarycenter");
      _TH1F_ClusterBarycenter_m[detid] = new TH1F(name,name,
					    Parameters.getParameter<int32_t>("Nbinx"),
					    Parameters.getParameter<double>("xmin"),
					    Parameters.getParameter<double>("xmax")
					    );

      sprintf(name,"PedestalsProfile_%s_%d",_StripGeomDetUnit->type().name().c_str(),detid);
      Parameters =  conf_.getParameter<edm::ParameterSet>("TH1PedestalsProfile");
      fFile->cd();fFile->cd("Pedestals");
      _TH1F_PedestalsProfile_m[detid] = new TH1F(name,name,
						 Parameters.getParameter<int32_t>("Nbinx"),
						 Parameters.getParameter<double>("xmin"),
						 Parameters.getParameter<double>("xmax")
						 );

      sprintf(name,"NoisesProfile_%s_%d",_StripGeomDetUnit->type().name().c_str(),detid);
      Parameters =  conf_.getParameter<edm::ParameterSet>("TH1NoisesProfile");
      fFile->cd();fFile->cd("Noises");
      _TH1F_NoisesProfile_m[detid] = new TH1F(name,name,
					      Parameters.getParameter<int32_t>("Nbinx"),
					      Parameters.getParameter<double>("xmin"),
					      Parameters.getParameter<double>("xmax")
					      );

      sprintf(name,"BadStripNoiseProfile_%s_%d",_StripGeomDetUnit->type().name().c_str(),detid);
      Parameters =  conf_.getParameter<edm::ParameterSet>("TH1BadStripNoiseProfile");
      fFile->cd();fFile->cd("BadStrips");
      _TH1F_BadStripNoiseProfile_m[detid] = new TH1F(name,name,
					      Parameters.getParameter<int32_t>("Nbinx"),
					      Parameters.getParameter<double>("xmin"),
					      Parameters.getParameter<double>("xmax")
					      );

    }

    std::string SubDet[3]={"TIB","TOB","TEC"};
    for (int i=0;i<3;i++){
      sprintf(name,"ClusterSignal_Cumulative_%s",SubDet[i].c_str());
      Parameters =  conf_.getParameter<edm::ParameterSet>("TH1ClusterSignal");
      fFile->cd();fFile->cd("ClusterSignal");
      _TH1F_ClusterSignal_v.push_back(new TH1F(name,name,
					Parameters.getParameter<int32_t>("Nbinx"),
					Parameters.getParameter<double>("xmin"),
					Parameters.getParameter<double>("xmax")
					)
			       );
      sprintf(name,"ClusterStoN_Cumulative_%s",SubDet[i].c_str());
      Parameters =  conf_.getParameter<edm::ParameterSet>("TH1ClusterStoN");
      fFile->cd();fFile->cd("ClusterStoN");
      _TH1F_ClusterStoN_v.push_back(new TH1F(name,name,
					     Parameters.getParameter<int32_t>("Nbinx"),
					     Parameters.getParameter<double>("xmin"),
					     Parameters.getParameter<double>("xmax")
					     )
				    );
      sprintf(name,"Noises_Cumulative_%s",SubDet[i].c_str());
      Parameters =  conf_.getParameter<edm::ParameterSet>("TH1Noises");
      fFile->cd();fFile->cd("Noises");
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

    fFile->cd();

    for(TrackerGeometry::DetUnitContainer::const_iterator it = tkgeom->detUnits().begin(); it != tkgeom->detUnits().end(); it++){           

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
	  //Fill BadStripNoise
	  edm::LogInfo("TestCluster") << "[TestCluster::endJob] Fill BadStripNoise detid " << detid << " strip " << istrip;
	  _TH1F_BadStripNoiseProfile_m.find(detid)->second->Fill(istrip,SiStripNoiseService_.getDisable(detid,istrip)?1.:0.);

	  int iSubDet=_StripGeomDetUnit->specificType().subDetector()-1;
	  _TH1F_Noises_v[iSubDet]->Fill(SiStripNoiseService_.getNoise(detid,istrip));
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
	if (hiter->second->GetMean()==0){
	  delete hiter->second;
	  _TH1F_ClusterSignal_m.erase(hiter);
	}
      }
      {
	std::map<uint32_t,TH1F*>::iterator hiter = _TH1F_ClusterStoN_m.find(detid);
	if (hiter->second->GetMean()==0){
	  delete hiter->second;
	  _TH1F_ClusterStoN_m.erase(hiter);
	}
      }
     {
      std::map<uint32_t,TH1F*>::iterator hiter = _TH1F_ClusterBarycenter_m.find(detid);
	if (hiter->second->GetMean()==0){
	  delete hiter->second;
	  _TH1F_ClusterBarycenter_m.erase(hiter);
	}
        }

      {
	std::map<uint32_t,TH1F*>::iterator hiter = _TH1F_PedestalsProfile_m.find(detid);
	if (hiter->second->GetEntries() == 0){
	  delete hiter->second;
	  _TH1F_PedestalsProfile_m.erase(hiter);
	}
      }
      {
	std::map<uint32_t,TH1F*>::iterator hiter = _TH1F_NoisesProfile_m.find(detid);
	if (hiter->second->GetEntries() == 0){
	  delete hiter->second;
	  _TH1F_NoisesProfile_m.erase(hiter);
	}
      }
           {
	std::map<uint32_t,TH1F*>::iterator hiter = _TH1F_BadStripNoiseProfile_m.find(detid);
	if (hiter->second->GetMean() == 0){
	  delete hiter->second;
	  _TH1F_BadStripNoiseProfile_m.erase(hiter);
	}
      } 
    }

    //fTree->Print();
    //fTree->Write();
    fFile->ls();
    fFile->Write();
    fFile->Close();
  }

  void TestCluster::analyze(const edm::Event& e, const edm::EventSetup& es) {
    edm::LogInfo("TestCluster") << "[TestCluster::analyse]  " << "Run " << e.id().run() << " Event " << e.id().event() << std::endl;

    // ClusterEvent_->Clear();
    
    runNb   = e.id().run();
    eventNb = e.id().event();
    std::cout << "Processing run " << runNb << " event " << eventNb << std::endl;

    //Get input 
    edm::Handle< edm::DetSetVector<SiStripCluster> >  input;
    e.getByLabel( src_, input);
    
    SiStripNoiseService_.setESObjects(es);
    SiStripPedestalsService_.setESObjects(es);

    //Loop on Dets
    edm::DetSetVector<SiStripCluster>::const_iterator DSViter=input->begin();
    for (; DSViter!=input->end();DSViter++){
      uint32_t detid = DSViter->id;
      const StripGeomDetUnit*_StripGeomDetUnit = dynamic_cast<const StripGeomDetUnit*>(tkgeom->idToDetUnit(DetId(detid)));
            
      int clusize=0;      
      //std::vector<Cluster> vCluster;
      //Loop on Clusters
      for(edm::DetSet<SiStripCluster>::const_iterator ic = DSViter->data.begin(); ic!=DSViter->data.end(); ic++) {
	
	//Cluster aCluster;
	
	clusize = ic->amplitudes().size();
	float barycenter=ic->barycenter();
	float Signal=0;
	float noise2=0;
	int count=0;	  
	const std::vector<uint16_t> amplitudes=ic->amplitudes();
	for(size_t i=0; i<amplitudes.size();i++)
	  if (amplitudes[i]>0){
	    Signal+=amplitudes[i];
	    noise2+=SiStripNoiseService_.getNoise(detid,ic->firstStrip()+i)*SiStripNoiseService_.getNoise(detid,ic->firstStrip()+i);
	    count++;

	    //Find strip with max charge
	//     if (aCluster.clMaxCharge<amplitudes[i]){
//  	      aCluster.clMaxCharge=amplitudes[i];
//  	      aCluster.clMaxPosition=i;
	    //    }
	  }

	//Evaluate Ql and Qr
// 	for(size_t i=0; i<amplitudes.size();i++){
//  	  if (i<aCluster.clMaxPosition)
//  	    aCluster.clNeighbourChargeL+=amplitudes[i];
	  
//  	  if (i>aCluster.clMaxPosition)
//  	    aCluster.clNeighbourChargeR+=amplitudes[i];
// 	}
	
// 	aCluster.DetId=detid;
// 	aCluster.clCharge=Signal;
// 	aCluster.clNoise=sqrt(noise2/count);
// 	aCluster.clPosition=ic->barycenter();
// 	aCluster.clWidth=clusize;
// 	aCluster.clMaxPosition+=ic->firstStrip();
	
	//Fill Histos
	_TH1F_ClusterSignal_m.find(detid)->second->Fill(Signal);
	_TH1F_ClusterStoN_m.find(detid)->second->Fill(Signal/sqrt(noise2/count));
	_TH1F_ClusterBarycenter_m.find(detid)->second->Fill(barycenter);
	
	int iSubDet=_StripGeomDetUnit->specificType().subDetector()-1;
	_TH1F_ClusterSignal_v[iSubDet]->Fill(Signal);
	_TH1F_ClusterStoN_v[iSubDet]->Fill(Signal/sqrt(noise2/count));
	
	//fill temp vector container
	//vCluster.push_back(aCluster);
      
      } //close loop on clusters
      
//       if (vCluster.size()){
// 	std::stable_sort(&vCluster[0],&vCluster[0]+vCluster.size());
//     	//insert in the event
// 	ClusterEvent_->Add(detid,vCluster);
//       }
    } //close loop on detectors
//     std::cout<< "pprima di fill" <<std::endl;
//     fTree->Fill();
//     std::cout<< "dopo di fill" <<std::endl;
  }
}


