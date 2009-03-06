import FWCore.ParameterSet.Config as cms

process = cms.Process('TEST')
process.add_( cms.Service("Timing"))
process.load("PerfTools.Callgrind.callgrindSwitch_cfi")
process.load('Configuration/StandardSequences/Services_cff')
process.load('FWCore/MessageService/MessageLogger_cfi')
process.MessageLogger = cms.Service("MessageLogger",
                                    debugModules = cms.untracked.vstring(),
                                    log = cms.untracked.PSet( threshold = cms.untracked.string('INFO') ),
                                    destinations = cms.untracked.vstring('log.txt'))

# Configuration which varies with source
process.load('Configuration/StandardSequences/GeometryIdeal_cff')
process.load('Configuration/StandardSequences/MagneticField_38T_cff')
process.load('Configuration/StandardSequences/FrontierConditions_GlobalTag_cff')
process.GlobalTag.globaltag = 'IDEAL_30X::All'

process.load('Configuration/StandardSequences/RawToDigi_cff')

process.maxEvents = cms.untracked.PSet(input = cms.untracked.int32(20))
process.source = cms.Source("PoolSource", fileNames = cms.untracked.vstring(
    '/store/relval/CMSSW_3_1_0_pre2/RelValTTbar/GEN-SIM-DIGI-RAW-HLTDEBUG/IDEAL_30X_v1/0000/023BACD4-8103-DE11-A2E6-001617C3B6CE.root'))
#---------------------------------------------------------------------------

# Configuration which varies depending on what to compare
process.NewClusterizer = cms.EDProducer("SiStripClusterizer",
                                        Algorithm = cms.string("ThreeThresholdAlgorithm"),
                                        ChannelThreshold = cms.double(2),
                                        SeedThreshold    = cms.double(3),
                                        ClusterThreshold = cms.double(5),
                                        MaxSequentialHoles = cms.uint32(0),
                                        MaxSequentialBad   = cms.uint32(0),
                                        MaxAdjacentBad     = cms.uint32(1),
                                        DigiProducersList = cms.VInputTag(
    cms.InputTag('siStripDigis','ZeroSuppressed'),
    cms.InputTag('siStripZeroSuppression','VirginRaw'),
    cms.InputTag('siStripZeroSuppression','ProcessedRaw'),
    cms.InputTag('siStripZeroSuppression','ScopeMode'))
                                        )
process.OldClusterizer = cms.EDProducer("SiStripClusterizer",
                                        Algorithm = cms.string("OldAlgorithm"),
                                        ChannelThreshold = cms.double(2),
                                        SeedThreshold    = cms.double(3),
                                        ClusterThreshold = cms.double(5),
                                        MaxSequentialHoles = cms.uint32(0),
                                        DigiProducersList = cms.VInputTag(
    cms.InputTag('siStripDigis','ZeroSuppressed'),
    cms.InputTag('siStripZeroSuppression','VirginRaw'),
    cms.InputTag('siStripZeroSuppression','ProcessedRaw'),
    cms.InputTag('siStripZeroSuppression','ScopeMode'))
                                        )
process.CompareClusters = cms.EDAnalyzer("CompareClusters",
                                         Clusters1 = cms.InputTag('OldClusterizer',''),
                                         Clusters2 = cms.InputTag('NewClusterizer',''),
                                         Digis     = cms.InputTag('siStripDigis','ZeroSuppressed')
                                         )

process.p1 = cms.Path(   process.siStripDigis *

                         process.profilerStart *
                         process.OldClusterizer *
                         process.NewClusterizer *
                         process.profilerStop *
                         
                         process.CompareClusters
                         )
