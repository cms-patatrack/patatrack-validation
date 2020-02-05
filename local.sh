# Local CMSSW installation
VO_CMS_SW_DIR=/data/cmssw

# OAuth token to post comments on GitHub
OAUTH_FILE=$HOME/.patatrack-validation.oauth

# Local cache of the input files
LOCAL_CACHE_PATH=/gpu_data

# Local cache of the input files
TTBAR_CACHE_PATH="file:$LOCAL_CACHE_PATH/store/relval/CMSSW_11_0_0_patch1/RelValTTbar_13/GEN-SIM-DIGI-RAW/PU25ns_110X_upgrade2018_realistic_v7_forTrk_rsb-v1/20000"
TTBAR_CACHE_FILE="0BF06666-13F7-0749-BA38-6E679A631FA0.root,1249A986-5981-9240-A57E-387A6AB46941.root"
ZMUMU_CACHE_PATH="file:$LOCAL_CACHE_PATH/store/relval/CMSSW_11_0_0_patch1/RelValZMM_13/GEN-SIM-DIGI-RAW/110X_upgrade2018_realistic_v7_forTrk-v1/20000"
ZMUMU_CACHE_FILE="06858195-2C07-FE40-BCBA-8272715FF982.root,3898A2CC-EA16-3048-80A2-8BB680AF5E00.root"
TTBARDESIGN_CACHE_PATH="file:$LOCAL_CACHE_PATH/store/relval/CMSSW_11_0_0_patch1/RelValTTbar_13/GEN-SIM-DIGI-RAW/PU25ns_110X_upgrade2018_design_v3_forTrk-v1/20000/"
TTBARDESIGN_CACHE_FILE="30E32A12-1DA1-624F-9EBC-83E5D527FA19.root,323F84D5-DFBB-5E47-B6B7-1D3BF6CC1905.root"

L1ACCEPT_CACHE_PATH="file:$LOCAL_CACHE_PATH/store/data/Run2018D/EphemeralHLTPhysics1/RAW/v1/000/323/775/00000"
L1ACCEPT_CACHE_FILE="A27DFA33-8FCB-BE42-A2D2-1A396EEE2B6E.root"

# URL and local area for uploading validation plots, profiles and logs
UPLOAD_URL="https://patatrack.web.cern.ch/patatrack/validation/pulls"
UPLOAD_DIR="/eos/home-f/fpantale/www/patatrack-website/validation/pulls"
LOCAL_DIR="/data/user/$USER/patatrack-validation/pulls"
