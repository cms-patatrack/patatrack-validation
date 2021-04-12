# Default global tag and number of events
GLOBALTAG="auto:phase1_2021_realistic"
NUMEVENTS=200

# Datasets used as input for the matrix-like tests
SAMPLES="TTBAR ZMUMU" # ZEE ZTT

# Data samples
DATA_SAMPLES="L1ACCEPT"

# TTbar sample, with 2021 "realistic" conditions and pileup
TTBAR="/RelValTTbar_14TeV/CMSSW_11_3_0_pre5-PU_113X_mcRun3_2021_realistic_v7-v1/GEN-SIM-DIGI-RAW"
TTBAR_CACHE_PATH="/store/relval/CMSSW_11_3_0_pre5/RelValTTbar_14TeV/GEN-SIM-DIGI-RAW/PU_113X_mcRun3_2021_realistic_v7-v1/00000"
TTBAR_CACHE_FILE="13fe6ebe-06f0-4932-80cd-90fa4493eba6.root,d3b63911-91f9-4167-b3c8-3010d63a376a.root"
TTBAR_NUMEVENTS=100

# Z -> mumu sample, with 2021 "realistic" conditions, no pileup
ZMUMU="/RelValZMM_14/CMSSW_11_3_0_pre5-113X_mcRun3_2021_realistic_v7-v1/GEN-SIM-DIGI-RAW"
ZMUMU_CACHE_PATH="/store/relval/CMSSW_11_3_0_pre5/RelValZMM_14/GEN-SIM-DIGI-RAW/113X_mcRun3_2021_realistic_v7-v1/00000"
ZMUMU_CACHE_FILE="9904ad4a-a5f6-473f-b035-2133fe5772d9.root,6352ccde-adc9-4004-a749-ecbb72207fbd.root"
ZMUMU_NUMEVENTS=200

# Z -> ee sample, with 2021 "realistic" conditions, no pileup
ZEE="/RelValZEE_14/CMSSW_11_3_0_pre5-113X_mcRun3_2021_realistic_v7-v1/GEN-SIM-DIGI-RAW"
ZEE_CACHE_PATH="/store/relval/CMSSW_11_3_0_pre5/RelValZEE_14/GEN-SIM-DIGI-RAW/113X_mcRun3_2021_realistic_v7-v1/00000"
ZEE_CACHE_FILE="4bea21c0-b9be-4e4e-8282-bb37ec7aa8c4.root"
ZEE_NUMEVENTS=200

# Z -> tautau sample, with 2021 "realistic" conditions, no pileup
ZTT="/RelValZTT_14/CMSSW_11_3_0_pre5-113X_mcRun3_2021_realistic_v7-v1/GEN-SIM-DIGI-RAW"
ZTT_CACHE_PATH="/store/relval/CMSSW_11_3_0_pre5/RelValZTT_14/GEN-SIM-DIGI-RAW/113X_mcRun3_2021_realistic_v7-v1/00000"
ZTT_CACHE_FILE="a954d504-058b-45d2-a1e2-e22aa50d3aad.root"
ZTT_NUMEVENTS=200

# Level-1 Trigger selected events, from Run2018D data taking era, pileup 50
L1ACCEPT="/EphemeralHLTPhysics1/Run2018D-v1/RAW run=323775 lumi=53"
L1ACCEPT_CACHE_PATH="/store/data/Run2018D/EphemeralHLTPhysics1/RAW/v1/000/323/775/00000"
L1ACCEPT_CACHE_FILE="A27DFA33-8FCB-BE42-A2D2-1A396EEE2B6E.root"
L1ACCEPT_NUMEVENTS=200
L1ACCEPT_GLOBALTAG="auto:run2_data_relval"
