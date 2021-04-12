# Number of threads and streams used in each job
THREADS=16
STREAMS=16

# runTheMatrix MC workflows (Run 3, 2021 relistic conditions)
PIXEL_CPU_WORKFLOWS="11634.501 11634.505"
PIXEL_GPU_WORKFLOWS="11634.502 11634.506"
ECAL_CPU_WORKFLOWS="11634.511"
ECAL_GPU_WORKFLOWS="11634.512"
HCAL_CPU_WORKFLOWS="11634.521"
HCAL_GPU_WORKFLOWS="11634.522"
CPU_WORKFLOWS="$PIXEL_CPU_WORKFLOWS $ECAL_CPU_WORKFLOWS $HCAL_CPU_WORKFLOWS"
GPU_WORKFLOWS="$PIXEL_GPU_WORKFLOWS $ECAL_GPU_WORKFLOWS $HCAL_GPU_WORKFLOWS"
WORKFLOWS="$PIXEL_CPU_WORKFLOWS $PIXEL_GPU_WORKFLOWS $ECAL_CPU_WORKFLOWS $ECAL_GPU_WORKFLOWS $HCAL_CPU_WORKFLOWS $HCAL_GPU_WORKFLOWS"

# runTheMatrix data Workflows (Run 2, 2018)
DATA_CPU_WORKFLOWS=""
DATA_GPU_WORKFLOWS="136.885502 136.885512 136.885522"
DATA_WORKFLOWS="$DATA_CPU_WORKFLOWS $DATA_GPU_WORKFLOWS"

GPU_WORKFLOWS="$GPU_WORKFLOWS $DATA_GPU_WORKFLOWS"

# Enable validation selected workflows
PIXEL_VALIDATION="11634.5 11634.501 11634.502 11634.505 11634.506"
ECAL_VALIDATION=""
HCAL_VALIDATION=""
VALIDATE="$PIXEL_VALIDATION $ECAL_VALIDATION $HCAL_VALIDATION"

# Enable profiling for selected workflows
PIXEL_PROFILING="11634.502 11634.506 136.885502"
PIXEL_PROFILING_FILE=RecoTracker/Configuration/customizePixelOnlyForProfiling
PIXEL_PROFILING_FUNC=customizePixelOnlyForProfilingGPUOnly
ECAL_PROFILING="11634.512 136.885512"
ECAL_PROFILING_FILE=RecoLocalCalo/Configuration/customizeEcalOnlyForProfiling
ECAL_PROFILING_FUNC=customizeEcalOnlyForProfilingGPUOnly
HCAL_PROFILING="11634.522 136.885522"
HCAL_PROFILING_FILE=RecoLocalCalo/Configuration/customizeHcalOnlyForProfiling
HCAL_PROFILING_FUNC=customizeHcalOnlyForProfilingGPUOnly
PROFILING="$PIXEL_PROFILING $ECAL_PROFILING $HCAL_PROFILING"

# Enable memcheck for selected workflows
SANITIZE="11634.502 11634.506 11634.512 11634.522"

# Default number of events (overridden with sample-specific values in input.sh)
NUMEVENTS=100

# Number of events for the memcheck workflows
SANITIZER_NUMEVENTS=10


function get_profiling_file() {
  local WORKFLOW="$1"
  [ "$WORKFLOW" ] || return
  echo "$PIXEL_PROFILING" | grep -q -w "$WORKFLOW" && echo "$PIXEL_PROFILING_FILE"
  echo "$ECAL_PROFILING"  | grep -q -w "$WORKFLOW" && echo "$ECAL_PROFILING_FILE"
  echo "$HCAL_PROFILING"  | grep -q -w "$WORKFLOW" && echo "$HCAL_PROFILING_FILE"
}

function get_profiling_function() {
  local WORKFLOW="$1"
  [ "$WORKFLOW" ] || return
  echo "$PIXEL_PROFILING" | grep -q -w "$WORKFLOW" && echo "$PIXEL_PROFILING_FUNC"
  echo "$ECAL_PROFILING"  | grep -q -w "$WORKFLOW" && echo "$ECAL_PROFILING_FUNC"
  echo "$HCAL_PROFILING"  | grep -q -w "$WORKFLOW" && echo "$HCAL_PROFILING_FUNC"
}

function get_workflow_group() {
  local WORKFLOW="$1"
  if echo "$GPU_WORKFLOWS" | grep -q -w "$WORKFLOW"; then
    echo gpu
  else
    echo all
  fi
}
