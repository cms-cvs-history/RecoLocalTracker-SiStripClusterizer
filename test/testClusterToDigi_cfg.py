import FWCore.ParameterSet.Config as cms

process = cms.Process('TEST')

process.MessageLogger = cms.Service("MessageLogger",
                                    debugModules = cms.untracked.vstring("*"),
                                    log = cms.untracked.PSet(threshold = cms.untracked.string('INFO')),
                                    destinations = cms.untracked.vstring('log')
                                    )


process.source = cms.Source ( "PoolSource",
                              fileNames = cms.untracked.vstring(""),
                              secondaryFileNames = cms.untracked.vstring()
                              )


#------------------------------------------
# Load standard sequences.
#------------------------------------------
process.load('Configuration/StandardSequences/MagneticField_AutoFromDBCurrent_cff')
process.load('Configuration/StandardSequences/GeometryIdeal_cff')


process.load("Configuration.StandardSequences.FrontierConditions_GlobalTag_cff")

process.load("Configuration/StandardSequences/RawToDigi_Data_cff")
process.load("Configuration/StandardSequences/Reconstruction_cff")
process.load('Configuration/EventContent/EventContent_cff')

#------------------------------------------
# Load ClusterToDigiProducer
#------------------------------------------

process.load('RecoLocalTracker.SiStripClusterizer.SiStripClusterToDigiProducer_cfi')

process.siStripClustersNew = process.siStripClusters.clone()
for inTag in process.siStripClustersNew.DigiProducersList:
    inTag.moduleLabel = "siStripClustersToDigis"

#------------------------------------------
# Load 
#------------------------------------------

process.FEVTEventContent.outputCommands.append('drop *_MEtoEDMConverter_*_*')
process.recotrackout = cms.OutputModule("PoolOutputModule",
                                        outputCommands = cms.untracked.vstring("drop *"
                                                                               , "keep *_*_*_TEST"
                                                                               ),
                                        fileName = cms.untracked.string('testClusterToDigi.root')
                                        )


#------------------------------------------
# Load DQM 
#------------------------------------------

process.DQMStore = cms.Service("DQMStore")
process.TkDetMap = cms.Service("TkDetMap")
process.SiStripDetInfoFileReader = cms.Service("SiStripDetInfoFileReader")

process.load("DQM.SiStripMonitorCluster.SiStripMonitorCluster_cfi")

process.SiStripMonitorClusterNew = process.SiStripMonitorCluster.clone()
process.SiStripMonitorClusterNew.TopFolderName = "ClusterToDigi"
process.SiStripMonitorClusterNew.ClusterProducer = 'siStripClustersNew'

#------------------------------------------
# Paths
#------------------------------------------

process.outpath = cms.EndPath(process.siStripDigis+
                              process.siStripZeroSuppression+
                              process.siStripClusters+
                              process.SiStripMonitorCluster+
                              process.siStripClustersToDigis+
                              process.siStripClustersNew+
                              process.SiStripMonitorClusterNew+
                              process.recotrackout)


#---------------------------------------------------------
# Run Dependent Configuration
#---------------------------------------------------------


process.DefaultClusterizer.RemoveApvShots = cms.bool(False)

process.SiStripMonitorCluster.TH1ClusterWidth.Nbinx = cms.int32(129)
process.SiStripMonitorCluster.TH1ClusterWidth.xmax  = cms.double(128.5)
process.SiStripMonitorCluster.OutputMEsInRootFile   = cms.bool(True)

process.GlobalTag.globaltag = 'GR09_R_34X_V3::All'

process.maxEvents = cms.untracked.PSet( input = cms.untracked.int32(1) )

process.source.fileNames = cms.untracked.vstring("/store/data/BeamCommissioning09/MinimumBias/RAW-RECO/BSCNOBEAMHALO-Dec19thSkim_341_v2/0004/DABDF3FC-94ED-DE11-8538-00304867BFC6.root")


