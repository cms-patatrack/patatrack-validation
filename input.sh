# Default global tag and number of events
GLOBALTAG="auto:phase1_2021_realistic"
NUMEVENTS=200

# Datasets used as input for the matrix-like tests
SAMPLES="TTBAR ZMUMU" # ZEE ZTT

# Data samples
DATA_SAMPLES="L1ACCEPT"

# TTbar sample, with 2021 "realistic" conditions and pileup
TTBAR="/RelValTTbar_14TeV/CMSSW_12_2_0_pre2-PU_122X_mcRun3_2021_realistic_v1-v3/GEN-SIM-DIGI-RAW"
TTBAR_CACHE_PATH="/store/relval/CMSSW_12_2_0_pre2/RelValTTbar_14TeV/GEN-SIM-DIGI-RAW/PU_122X_mcRun3_2021_realistic_v1-v3/2580000"
TTBAR_CACHE_FILE="29814f34-bdd3-4f68-89b7-c27754152787.root"
TTBAR_NUMEVENTS=100

# Z -> mumu sample, with 2021 "realistic" conditions, no pileup
ZMUMU="/RelValZMM_14/CMSSW_12_2_0_pre2-122X_mcRun3_2021_realistic_v1-v1/GEN-SIM-DIGI-RAW"
ZMUMU_CACHE_PATH="/store/relval/CMSSW_12_2_0_pre2/RelValZMM_14/GEN-SIM-DIGI-RAW/122X_mcRun3_2021_realistic_v1-v1/2580000"
ZMUMU_CACHE_FILE="02369a2c-0164-46c1-85cf-94f4b811c7ad.root"
ZMUMU_NUMEVENTS=200

# Z -> ee sample, with 2021 "realistic" conditions, no pileup
ZEE="/RelValZEE_14/CMSSW_12_2_0_pre2-122X_mcRun3_2021_realistic_v1-v1/GEN-SIM-DIGI-RAW"
ZEE_CACHE_PATH="/store/relval/CMSSW_12_2_0_pre2/RelValZEE_14/GEN-SIM-DIGI-RAW/122X_mcRun3_2021_realistic_v1-v1/2580000"
ZEE_CACHE_FILE="06e824c5-0606-453c-942e-da12fc529757.root"
ZEE_NUMEVENTS=200

# Z -> tautau sample, with 2021 "realistic" conditions, no pileup
ZTT="/RelValZTT_14/CMSSW_12_2_0_pre2-122X_mcRun3_2021_realistic_v1-v1/GEN-SIM-DIGI-RAW"
ZTT_CACHE_PATH="/store/relval/CMSSW_12_2_0_pre2/RelValZTT_14/GEN-SIM-DIGI-RAW/122X_mcRun3_2021_realistic_v1-v1/2580000"
ZTT_CACHE_FILE="40ec2eb0-3f1e-4412-a20b-18a919b0b9cb.root"
ZTT_NUMEVENTS=200

# Level-1 Trigger selected events, from Run2018D data taking era, pileup 50
L1ACCEPT="/EphemeralHLTPhysics1/Run2018D-v1/RAW run=323775 lumi=53"
L1ACCEPT_CACHE_PATH="/store/data/Run2018D/EphemeralHLTPhysics1/RAW/v1/000/323/775/00000"
L1ACCEPT_CACHE_FILE="A27DFA33-8FCB-BE42-A2D2-1A396EEE2B6E.root"
L1ACCEPT_NUMEVENTS=200
L1ACCEPT_GLOBALTAG="auto:run2_data_relval"
