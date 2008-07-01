import FWCore.ParameterSet.Config as cms

siStripClusters = cms.EDFilter("SiStripClusterizer",
    MaxHolesInCluster = cms.int32(0),
    ChannelThreshold = cms.double(2.0),
    DigiProducersList = cms.VPSet(cms.PSet(
        DigiLabel = cms.string('\0'),
        DigiProducer = cms.string('simSiStripDigis')
    )),
    ClusterMode = cms.string('ThreeThresholdClusterizer'),
    SeedThreshold = cms.double(3.0),
    SiStripQualityLabel = cms.string(''), ##Use SiStripQualityLabel="NULL" to use self build empty SiStripQuality  

    ClusterThreshold = cms.double(5.0)
)


