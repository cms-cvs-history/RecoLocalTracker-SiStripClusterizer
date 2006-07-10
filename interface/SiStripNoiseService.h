#ifndef SISTRIPCLUSTERIZER_SISTRIPNOISESERVICE_H
#define SISTRIPCLUSTERIZER_SISTRIPNOISESERVICE_H

//edm
#include "FWCore/Framework/interface/EventSetup.h"
#include "FWCore/Framework/interface/ESHandle.h"
#include "FWCore/ParameterSet/interface/ParameterSet.h"
#include "FWCore/MessageLogger/interface/MessageLogger.h"
//ES Data
#include "CondFormats/SiStripObjects/interface/SiStripNoises.h" 
#include "CondFormats/DataRecord/interface/SiStripNoisesRcd.h"
//Geometry
#include "Geometry/TrackerGeometryBuilder/interface/TrackerGeometry.h"
#include "Geometry/Records/interface/TrackerDigiGeometryRecord.h"
#include "Geometry/CommonTopologies/interface/StripTopology.h"
#include "Geometry/TrackerGeometryBuilder/interface/StripGeomDetType.h"
#include "Geometry/TrackerGeometryBuilder/interface/StripGeomDetUnit.h"

#include "CLHEP/Random/RandFlat.h"

class SiStripNoiseService {

 public:
  SiStripNoiseService(const edm::ParameterSet& conf);
  ~SiStripNoiseService(){};
  
  void setESObjects( const edm::EventSetup& es );
  float getNoise   (const uint32_t& detID,const uint16_t& strip) ;
  bool  getDisable (const uint32_t& detID,const uint16_t& strip) ;

 private:
  edm::ParameterSet conf_;
  bool UseCalibDataFromDB_;

  double ElectronsPerADC_;
  double ENC_;
  double BadStripProbability_;

  edm::ESHandle<SiStripNoises> noise;
  edm::ESHandle<TrackerGeometry> tkgeom;

  SiStripNoises::Range old_range;
  uint32_t old_detID;
  float    old_noise;
};

#endif
