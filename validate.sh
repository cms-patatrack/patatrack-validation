# Directory with the validation scripts
VALIDATION=$(readlink -f $(dirname ${BASH_SOURCE[0]}))

# cuda Compute Sanitizer options
SANITIZER_TOOL="compute-sanitizer"
SANITIZER_OPTS="--launch-timeout 0 --kill yes --error-exitcode 127 --require-cuda-init yes --nvtx --print-level info --demangle full"
MEMCHECK_OPTS="--leak-check full --report-api-errors all"
INITCHECK_OPTS="--track-unused-memory no"
RACECHECK_OPTS=""
SYNCCHECK_OPTS=""

function report() {
  echo "$@" >> $REPORT
}

function apply() {
  PATTERN="$1"; shift
    for ARG; do echo $PATTERN | sed -e"s#%#$ARG#g"; done
}

function apply_and_glob() {
  echo $(apply "$@")
}

function has_validate() {
  local WORKFLOW=$1
  echo "$VALIDATE" | grep -q -w "$WORKFLOW"
}

function has_pixel_validation() {
  local WORKFLOW=$1
  echo "$PIXEL_VALIDATION" | grep -q -w "$WORKFLOW"
}

function has_profiling() {
  local WORKFLOW=$1
  echo "$PROFILING" | grep -q -w "$WORKFLOW"
}

function has_sanitizer() {
  local WORKFLOW=$1
  echo "$SANITIZE" | grep -q -w "$WORKFLOW"
}

function build_matrix() {
  local DIRNAME="$1"
  shift
  local WORKFLOWS="$@"
  local SAMPLE DATASET WORKDIR CACHE_PATH CACHE_FILE INPUT MY_GLOBALTAG MY_NUMEVENTS WORKFLOW
  # create the matrix-like workflows for the various samples
  cd $BASE/$DIRNAME
  eval $(scram runtime -sh)
  for SAMPLE in $SAMPLES; do
    DATASET=${!SAMPLE}
    WORKDIR=$(echo $DATASET | cut -d/ -f 2-3 --output-delimiter=-)
    CACHE_PATH=$(eval echo \$$(echo $SAMPLE)_CACHE_PATH)
    CACHE_FILE=$(eval echo \$$(echo $SAMPLE)_CACHE_FILE)
    if [ "$CACHE_PATH" ] && [ "$CACHE_FILE" ]; then
      INPUT="--dirin=$CACHE_PATH --filein $CACHE_FILE"
    else
      INPUT="--dasquery 'file dataset=$DATASET'"
    fi
    # customise the global tag and number of events by dataset, or use the default values
    MY_GLOBALTAG=$(eval echo \$$(echo $SAMPLE)_GLOBALTAG)
    MY_NUMEVENTS=$(eval echo \$$(echo $SAMPLE)_NUMEVENTS)
    echo "# prepare to run on ${MY_NUMEVENTS:=$NUMEVENTS} events on $DATASET with ${MY_GLOBALTAG:=$GLOBALTAG} conditions"
    mkdir -p $CMSSW_BASE/run/$WORKDIR
    cd $CMSSW_BASE/run/$WORKDIR
    local GROUP
    for WORKFLOW in $WORKFLOWS; do
    {
      # check the the workflow actually exists in the release
      GROUP=$(get_workflow_group $WORKFLOW)
      runTheMatrix.py -n -e -w $GROUP -l $WORKFLOW | grep -q ^$WORKFLOW || continue
      mkdir -p $WORKFLOW
      cd $WORKFLOW

      # extract step3 and step4 commands
      local STEP3="$(runTheMatrix.py -n -e -w $GROUP -l $WORKFLOW | grep 'cmsDriver.py step3' | cut -d: -f2- | sed -e"s#^ *##" -e"s# \+--conditions *[^ ]\+# --conditions $MY_GLOBALTAG#" -e"s# \+-n *[^ ]\+# -n $MY_NUMEVENTS#") --fileout file:step3.root"
      local STEP4="$(runTheMatrix.py -n -e -w $GROUP -l $WORKFLOW | grep 'cmsDriver.py step4' | cut -d: -f2- | sed -e"s#^ *##" -e"s# \+--conditions *[^ ]\+# --conditions $MY_GLOBALTAG#" -e"s# \+-n *[^ ]\+# -n $MY_NUMEVENTS#") --filein file:step3_inDQM.root"

      echo "# prepare workflow $WORKFLOW"
      $STEP3 $INPUT --no_exec --python_filename=step3.py
      $STEP4        --no_exec --python_filename=step4.py
      # show CUDAService messages and configure multithreading
      cat >> step3.py << @EOF

# Show CUDAService messages
#process.MessageLogger.categories.append("CUDAService")

# Configure multithreading
process.options.numberOfThreads = cms.untracked.uint32( $THREADS )
process.options.numberOfStreams = cms.untracked.uint32( $STREAMS )
process.options.numberOfConcurrentLuminosityBlocks = cms.untracked.uint32( 1 )
@EOF
      if echo ${MY_GLOBALTAG} | grep -q 2018_realistic; then
        # use cuts for "realistic" conditions
        cat >> step3.py << @EOF

# Use "realistic" cuts
if 'caHitNtupletCUDA' in process.__dict__:
  process.caHitNtupletCUDA.idealConditions = False
@EOF
      else
        # use cuts for "design" conditions
        cat >> step3.py << @EOF

# Use "design" cuts
if 'caHitNtupletCUDA' in process.__dict__:
  process.caHitNtupletCUDA.idealConditions = True
@EOF
      fi

      local PROFILING_FILE=$(get_profiling_file $WORKFLOW)
      local PROFILING_FUNC=$(get_profiling_function $WORKFLOW)
      if has_profiling $WORKFLOW && ( [ -f $CMSSW_RELEASE_BASE/python/${PROFILING_FILE}.py ] || [ -f $CMSSW_BASE/python/${PROFILING_FILE}.py ] ); then
        # create a profiling workflow
        $STEP3 $INPUT --no_exec --customise_unsch ${PROFILING_FILE}.${PROFILING_FUNC} --python_filename=profile.py
        # add the NVProfilerService to profile, show CUDAService messages and configure multithreading
        cat >> profile.py << @EOF

# Mark CMSSW transitions and modules in the nvprof profile
#from FWCore.ParameterSet.Utilities import moduleLabelsInSequences
#process.NVProfilerService = cms.Service("NVProfilerService",
#    highlightModules = cms.untracked.vstring( moduleLabelsInSequences(process.reconstruction_step) ),
#    showModulePrefetching = cms.untracked.bool( False )
#)

# Show CUDAService messages
#process.MessageLogger.categories.append("CUDAService")

# Configure multithreading
process.options.numberOfThreads = cms.untracked.uint32( $THREADS )
process.options.numberOfStreams = cms.untracked.uint32( $STREAMS )
process.options.numberOfConcurrentLuminosityBlocks = cms.untracked.uint32( 1 )
@EOF
        if echo ${MY_GLOBALTAG} | grep -q 2018_realistic; then
          # use cuts for "realistic" conditions
          cat >> profile.py << @EOF

# Use "realistic" cuts
if 'caHitNtupletCUDA' in process.__dict__:
  process.caHitNtupletCUDA.idealConditions = False
@EOF
        else
          # use cuts for "design" conditions
          cat >> profile.py << @EOF

# Use "design" cuts
if 'caHitNtupletCUDA' in process.__dict__:
  process.caHitNtupletCUDA.idealConditions = True
@EOF
        fi
      fi

      if has_sanitizer $WORKFLOW; then
        # prepare the workflow to run the various CUDA Compute Sanitizer checks
        if [ -f profile.py ]; then
          cp profile.py sanitizer.py
        else
          cp step3.py sanitizer.py
        fi
        (( SANITIZER_NUMEVENTS )) || local SANITIZER_NUMEVENTS=10
        cat >> sanitizer.py << @EOF

# Set the number of events for the memcheck workflows
process.maxEvents = cms.untracked.PSet(
    input = cms.untracked.int32($SANITIZER_NUMEVENTS)
)
@EOF
      fi

      cd ..
    } &
    done
    echo
  done
  wait
}

function build_data_matrix() {
  local DIRNAME="$1"
  shift
  local WORKFLOWS="$@"
  local SAMPLE DATASET WORKDIR CACHE_PATH CACHE_FILE INPUT MY_GLOBALTAG MY_NUMEVENTS WORKFLOW
  # create the matrix-like workflows for the various samples
  cd $BASE/$DIRNAME
  eval $(scram runtime -sh)
  for SAMPLE in $DATA_SAMPLES; do
    DATASET=${!SAMPLE}
    WORKDIR=$(echo $DATASET | cut -d/ -f 2-3 --output-delimiter=-)
    CACHE_PATH=$(eval echo \$$(echo $SAMPLE)_CACHE_PATH)
    CACHE_FILE=$(eval echo \$$(echo $SAMPLE)_CACHE_FILE)
    if [ "$CACHE_PATH" ] && [ "$CACHE_FILE" ]; then
      INPUT="--dirin=$CACHE_PATH --filein $CACHE_FILE"
    else
      INPUT="--dasquery 'file dataset=$DATASET'"
    fi
    # customise the global tag and number of events by dataset, or use the default values
    MY_GLOBALTAG=$(eval echo \$$(echo $SAMPLE)_GLOBALTAG)
    MY_NUMEVENTS=$(eval echo \$$(echo $SAMPLE)_NUMEVENTS)
    echo "# prepare to run on ${MY_NUMEVENTS:=$NUMEVENTS} events on $DATASET with ${MY_GLOBALTAG:=$GLOBALTAG} conditions"
    mkdir -p $CMSSW_BASE/run/$WORKDIR
    cd $CMSSW_BASE/run/$WORKDIR
    for WORKFLOW in $WORKFLOWS; do
    {
      # check the the workflow actually exists in the release
      GROUP=$(get_workflow_group $WORKFLOW)
      runTheMatrix.py -n -e -w $GROUP -l $WORKFLOW | grep -q ^$WORKFLOW || continue
      mkdir -p $WORKFLOW
      cd $WORKFLOW

      # copy the custom source modules
      cp $VALIDATION/parts/sourceFromRaw_${WORKDIR}_cff.py sourceFromRaw_cff.py

      # extract step3 and step4 commands
      local STEP3="$(runTheMatrix.py -n -e -w $GROUP -l $WORKFLOW | grep 'cmsDriver.py step3' | cut -d: -f2- | sed -e"s#^ *##" -e"s# \+--conditions *[^ ]\+# --conditions $MY_GLOBALTAG#" -e"s# \+-n *[^ ]\+# -n $MY_NUMEVENTS#") --fileout file:step3.root"
      local STEP4="$(runTheMatrix.py -n -e -w $GROUP -l $WORKFLOW | grep 'cmsDriver.py step4' | cut -d: -f2- | sed -e"s#^ *##" -e"s# \+--conditions *[^ ]\+# --conditions $MY_GLOBALTAG#" -e"s# \+-n *[^ ]\+# -n $MY_NUMEVENTS#") --filein file:step3_inDQM.root"

      echo "# prepare workflow $WORKFLOW"
      $STEP3 $INPUT --no_exec --python_filename=step3.py
      $STEP4        --no_exec --python_filename=step4.py
      # show CUDAService messages and configure multithreading
      cat >> step3.py << @EOF

# Override the source to use the DAQ source
import sys, os, inspect
sys.path.append(os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe()))))
process.load("sourceFromRaw_cff")

# Show CUDAService messages
#process.MessageLogger.categories.append("CUDAService")

# Configure multithreading
process.options.numberOfThreads = cms.untracked.uint32( $THREADS )
process.options.numberOfStreams = cms.untracked.uint32( $STREAMS )
process.options.numberOfConcurrentLuminosityBlocks = cms.untracked.uint32( 1 )

# Use "realistic" cuts
if 'caHitNtupletCUDA' in process.__dict__:
  process.caHitNtupletCUDA.idealConditions = False
@EOF

      local PROFILING_FILE=$(get_profiling_file $WORKFLOW)
      local PROFILING_FUNC=$(get_profiling_function $WORKFLOW)
      if has_profiling $WORKFLOW && ( [ -f $CMSSW_RELEASE_BASE/python/${PROFILING_FILE}.py ] || [ -f $CMSSW_BASE/python/${PROFILING_FILE}.py ] ); then
        # create a profiling workflow
        $STEP3 $INPUT --no_exec --customise_unsch ${PROFILING_FILE}.${PROFILING_FUNC} --python_filename=profile.py
        # add the NVProfilerService to profile, show CUDAService messages and configure multithreading
        cat >> profile.py << @EOF

# Override the source to use the DAQ source
import sys, os, inspect
sys.path.append(os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe()))))
process.load("sourceFromRaw_cff")

# Mark CMSSW transitions and modules in the nvprof profile
#from FWCore.ParameterSet.Utilities import moduleLabelsInSequences
#process.NVProfilerService = cms.Service("NVProfilerService",
#    highlightModules = cms.untracked.vstring( moduleLabelsInSequences(process.reconstruction_step) ),
#    showModulePrefetching = cms.untracked.bool( False )
#)

# Show CUDAService messages
#process.MessageLogger.categories.append("CUDAService")

# Configure multithreading
process.options.numberOfThreads = cms.untracked.uint32( $THREADS )
process.options.numberOfStreams = cms.untracked.uint32( $STREAMS )
process.options.numberOfConcurrentLuminosityBlocks = cms.untracked.uint32( 1 )

# Use "realistic" cuts
if 'caHitNtupletCUDA' in process.__dict__:
  process.caHitNtupletCUDA.idealConditions = False
@EOF
        touch .scan_profile
      fi

      if has_sanitizer $WORKFLOW; then
        # prepare the workflow to run the various CUDA Compute Sanitizer checks
        if [ -f profile.py ]; then
          cp profile.py sanitizer.py
        else
          cp step3.py sanitizer.py
        fi
        (( SANITIZER_NUMEVENTS )) || local SANITIZER_NUMEVENTS=10
        cat >> sanitizer.py << @EOF

# Set the number of events for the memcheck workflows
process.maxEvents = cms.untracked.PSet(
    input = cms.untracked.int32($SANITIZER_NUMEVENTS)
)
@EOF
      fi

      cd ..
    } &
    done
    echo
  done
  wait
}


function run_workflow() {
  local WORKDIR="$1"

  cd $BASE/$WORKDIR
  echo "# at $WORKDIR"
  eval $(scram runtime -sh)

  # (optional) run the validation
  if [ -f step3.py ]; then
    # run step 3
    echo -n "# running step3... "
    if cmsRun step3.py >& step3.log; then
      echo "done"
      touch step3.done
    else
      echo "failed"
      tail step3.log
      touch step3.fail
      # do not attempt to run other steps if step3 failed
      cd $BASE
      return
    fi

    # run step 4
    echo -n "# running step4... "
    if cmsRun step4.py >& step4.log; then
      echo "done"
      touch step4.done
    else
      echo "failed"
      tail step4.log
      touch step4.fail
    fi
  fi

  # (optional) run profile
  if [ -f profile.py ]; then
    echo -n "# running profile... "
    #if nvprof -f -o profile.nvvp -s --log-file profile.profile -- cmsRun profile.py >& profile.log; then
    if cmsRun profile.py >& profile.log; then
      echo "done"
      touch profile.done
    else
      echo "failed"
      tail profile.log
      touch profile.fail
    fi
    if [ -f .scan_profile ] && ! [ -f profile.fail ]; then
      echo -n "# scanning profile... "
      $BASE/patatrack-scripts/scan profile.py
    fi
  fi

  # (optional) run CUDA Compute Sanitizer
  if [ -f sanitizer.py ]; then
    # initcheck
    echo -n "# running $SANITIZER_TOOL --tool initcheck... "
    if $SANITIZER_TOOL $SANITIZER_OPTS --tool initcheck $SYNCCHECK_OPTS --log-file initcheck.out cmsRun sanitizer.py >& initcheck.log; then
      #[ -f initcheck.log ] && cat initcheck.log | c++filt -i > demangled && mv demangled initcheck.log
      echo "done"
      touch tool-initcheck.done
    else
      echo "failed"
      tail initcheck.out
      touch tool-initcheck.fail
    fi
    # memcheck
    echo -n "# running $SANITIZER_TOOL --tool memcheck... "
    if $SANITIZER_TOOL $SANITIZER_OPTS --tool memcheck $MEMCHECK_OPTS --log-file memcheck.out cmsRun sanitizer.py >& memcheck.log; then
      #[ -f memcheck.log ] && cat memcheck.log | c++filt -i > demangled && mv demangled memcheck.log
      echo "done"
      touch tool-memcheck.done
    else
      echo "failed"
      tail memcheck.out
      touch tool-memcheck.fail
    fi
    # synccheck
    echo -n "# running $SANITIZER_TOOL --tool synccheck... "
    if $SANITIZER_TOOL $SANITIZER_OPTS --tool synccheck $SYNCCHECK_OPTS --log-file synccheck.out cmsRun sanitizer.py >& synccheck.log; then
      #[ -f synccheck.log ] && cat synccheck.log | c++filt -i > demangled && mv demangled synccheck.log
      echo "done"
      touch tool-synccheck.done
    else
      echo "failed"
      tail synccheck.out
      touch tool-synccheck.fail
    fi
  fi

  cd $BASE
}

function run_workflows() {
  cd $BASE

  local WORKDIR
  for WORKDIR in $(apply_and_glob "%/run/*/*/" "$@"); do
    run_workflow $WORKDIR
  done
}

function run_workflows_in_parallel() {
  cd $BASE

  # create a named pipe
  local FIFO=$(mktemp -u pipeXXXXXXXXXX)
  mkfifo $FIFO
  exec 3<>$FIFO
  rm $FIFO

  # put in the fifo a token per GPU
  local GPU
  local TOKEN
  nvidia-smi -L | cut -d: -f1 | while read GPU TOKEN; do
    printf "%s," "$TOKEN" >&3
  done

  local MAXJOBS=$(($1))
  local WORKDIR
  for WORKDIR in $(apply_and_glob "%/run/*/*/" "$@"); do
    # block until a token is available
    local TOKEN
    read -u3 -d, TOKEN

    (
      # run the task in an asynchronous sub-shell
      CUDA_VISIBLE_DEVICES=$TOKEN run_workflow $WORKDIR

      # put back the token
      printf '%s,' $TOKEN >&3
    )&
  done

  # wait for all tasks to complete
  wait
}

# Make validation plots, based on the DQM output of step4 and makeTrackValidationPlots.py
# and upload them to the EOS www area.
#
# Usage:
#   make_validation_plots RELEASE [RELEASE ...]
#
function make_validation_plots() {
  [ "$1" ] || return 1
  local DIRNAME="${!#}"
  local -a RELEASES=("$@")
  cd $BASE/$DIRNAME
  eval $(scram runtime -sh)

  report "## Validation plots"

  local SAMPLE
  for SAMPLE in $SAMPLES; do
    local DATASET=${!SAMPLE}
    report "#### $DATASET"
    local WORKDIR=$(echo $DATASET | cut -d/ -f 2-3 --output-delimiter=-)
    mkdir -p $BASE/plots/$WORKDIR
    cd $BASE/plots/$WORKDIR

    # all releases and workflows
    local RELEASE
    for RELEASE in ${RELEASES[@]}; do
      local WORKFLOW
      for WORKFLOW in $WORKFLOWS $DATA_WORKFLOWS; do
        local PART=$(echo $RELEASE | cut -d/ -f1)-$WORKFLOW
        local FILE=$BASE/$RELEASE/run/$WORKDIR/$WORKFLOW/$DQMFILE
        [ -f $FILE ] && ln -sf $FILE ${PART}.root
        FILE=$BASE/$RELEASE/run/$WORKDIR/$WORKFLOW/scan.csv
        [ -f $FILE ] && ln -sf $FILE ${PART}.csv
      done
    done

    # validation of all workflows across all releases
    local WORKFLOW
    for WORKFLOW in $WORKFLOWS $DATA_WORKFLOWS; do
      mkdir -p $LOCAL_DIR/$JOBID/$WORKDIR/$WORKFLOW
      if has_pixel_validation $WORKFLOW; then
        local FILES=""
        local RELEASE
        for RELEASE in ${RELEASES[@]}; do
          local PART=$(echo $RELEASE | cut -d/ -f1)-$WORKFLOW
          [ -f ${PART}.root ] || continue
          FILES="$FILES ${PART}.root"
        done
        if [ "$FILES" ]; then
          makeTrackValidationPlots.py \
            --extended \
            --html-sample $DATASET \
            --html-validation-name $DATASET \
            --outputDir $LOCAL_DIR/$JOBID/$WORKDIR/$WORKFLOW \
            $FILES
          report "  - tracking validation [plots]($UPLOAD_URL/$JOBID/$WORKDIR/$WORKFLOW/index.html) and [summary]($UPLOAD_URL/$JOBID/$WORKDIR/$WORKFLOW/plots_summary.html) for workflow $WORKFLOW"
        else
          report "  - :warning: tracking validation plots and summary for workflow $WORKFLOW are **missing**"
        fi
      fi
    done
    report
  done
}

function make_gpucpu_plots() {
  [ "$1" ] || return 1
  local DIRNAME="${!#}"
  local -a RELEASES=("$@")
  cd $BASE/$DIRNAME
  eval $(scram runtime -sh)

  report "### Validation plots (CPU vs GPU)"

  local SAMPLE
  for SAMPLE in $SAMPLES; do
    local DATASET=${!SAMPLE}
    report "#### $DATASET"
    local WORKDIR=$(echo $DATASET | cut -d/ -f 2-3 --output-delimiter=-)
    mkdir -p $BASE/plots/gpu_vs_cpu/$WORKDIR
    cd $BASE/plots/gpu_vs_cpu/$WORKDIR

    # all releases and workflows
    local RELEASE
    for RELEASE in ${RELEASES[@]}; do
      local WORKFLOW
      for WORKFLOW in $PIXEL_GPU_WORKFLOWS $PIXEL_CPU_WORKFLOWS; do
        local PART=$(echo $RELEASE | cut -d/ -f1)-$WORKFLOW
        local FILE=$BASE/$RELEASE/run/$WORKDIR/$WORKFLOW/$DQMFILE
        [ -f $FILE ] && ln -sf $FILE ${PART}.root
        FILE=$BASE/$RELEASE/run/$WORKDIR/$WORKFLOW/scan.csv
        [ -f $FILE ] && ln -sf $FILE ${PART}.csv
      done
    done

    # validation of pixel workflows across all releases
    local GPU_WFS=($PIXEL_GPU_WORKFLOWS)
    local CPU_WFS=($PIXEL_CPU_WORKFLOWS)
    local NUMWFS=${#GPU_WFS[@]}
    local I
    for I in `seq 1 $NUMWFS`; do
      GPU_WORKFLOW=${GPU_WFS[$I-1]}
      CPU_WORKFLOW=${CPU_WFS[$I-1]}
      local PULLDIR=${CPU_WORKFLOW}_vs_${GPU_WORKFLOW}
      mkdir -p $LOCAL_DIR/$JOBID/$WORKDIR/$PULLDIR

      if has_pixel_validation $GPU_WORKFLOW && has_pixel_validation $CPU_WORKFLOW; then
        local FILES=""
        local RELEASE
        for RELEASE in ${RELEASES[@]}; do
          local CPU_PART=$(echo $RELEASE | cut -d/ -f1)-$CPU_WORKFLOW
          local GPU_PART=$(echo $RELEASE | cut -d/ -f1)-$GPU_WORKFLOW
          ( [ -f ${GPU_PART}.root ] && [ -f ${CPU_PART}.root ] ) || continue
          FILES="$FILES ${GPU_PART}.root"
          FILES="$FILES ${CPU_PART}.root"
        done
        if [ "$FILES" ]; then
          makeTrackValidationPlots.py \
            --extended \
            --html-sample $DATASET \
            --html-validation-name $DATASET \
            --outputDir $LOCAL_DIR/$JOBID/$WORKDIR/$PULLDIR \
            $(ls $FILES 2> /dev/null)
          report "  - tracking validation [plots]($UPLOAD_URL/$JOBID/$WORKDIR/$PULLDIR/index.html) and [summary]($UPLOAD_URL/$JOBID/$WORKDIR/$PULLDIR/plots_summary.html) for workflows $GPU_WORKFLOW and $CPU_WORKFLOW"
        else
          report "  - :warning: tracking validation plots and summary for workflows $GPU_WORKFLOW and $CPU_WORKFLOW are **missing**"
        fi
      fi
    done
    report
  done
}

# Make throughput plots, based on the scan of the benchmark of the profile,
# and upload them to the EOS www area.
#
# Usage:
#   make_throughput_plots RELEASE [RELEASE ...]
#
function make_throughput_plots() {
  [ "$1" ] || return 1
  local DIRNAME="${!#}"
  local -a RELEASES=("$@")
  cd $BASE/$DIRNAME
  eval $(scram runtime -sh)

  report "## Throughput plots"

  local SAMPLE
  for SAMPLE in $DATA_SAMPLES; do
    local DATASET=${!SAMPLE}
    report "#### $DATASET"
    local WORKDIR=$(echo $DATASET | cut -d/ -f 2-3 --output-delimiter=-)
    mkdir -p $BASE/plots/$WORKDIR
    cd $BASE/plots/$WORKDIR

    # throughput of all workflows across all releases
    local WORKFLOW
    for WORKFLOW in $DATA_WORKFLOWS; do
      mkdir -p $LOCAL_DIR/$JOBID/$WORKDIR/$WORKFLOW
      if has_profiling $WORKFLOW; then
        local FILES=""
        local RELEASE
        for RELEASE in ${RELEASES[@]}; do
          local PART=$(echo $RELEASE | cut -d/ -f1)-$WORKFLOW
          local FILE=$BASE/$RELEASE/run/$WORKDIR/$WORKFLOW/scan.csv
          if [ -f $FILE ]; then
            ln -sf $FILE ${PART}.csv
            FILES="$FILES ${PART}.csv"
          fi
        done
        if [ "$FILES" ]; then
          if $BASE/patatrack-scripts/plot_scan.py $FILES -o $LOCAL_DIR/$JOBID/$WORKDIR/scan-${WORKFLOW}.png -z $LOCAL_DIR/$JOBID/$WORKDIR/zoom-${WORKFLOW}.png; then
            # Note: the GitHub API does not support uploading files; the link will be dangling until
            # the plots are updloaded
            report "![scan-${WORKFLOW}.png]($UPLOAD_URL/$JOBID/$WORKDIR/scan-${WORKFLOW}.png)"
            report "![zoom-${WORKFLOW}.png]($UPLOAD_URL/$JOBID/$WORKDIR/zoom-${WORKFLOW}.png)"
          fi
        fi
      fi
    done
    report
  done
}

# If the source file exists, dereference any symlinks amd copy it preserving mode, ownership, and timestamps
#
# Usage
#  copy_if_exists SRC DST
#
function copy_if_exists() {
  [ -f "$1" ] && cp -p -L "$1" "$2" || true
}

# Upload the output of a validation job
#
# Usage
#  upload_artefacts RELEASE WORKDIR WORKFLOW NAME
#
function upload_artefacts() {
  local RELEASE=$1
  local WORKDIR=$2
  local WORKFLOW=$3
  local CWD=$BASE/$RELEASE/run/$WORKDIR/$WORKFLOW

  # skip invalid combinations of datasets and workflows
  if ! [ -d $CWD ]; then
    return
  fi
  report "  - $RELEASE release, workflow $WORKFLOW"

  # check the artefacts to look for and upload
  NAMES=
  [ -f $CWD/step3.py ]   && NAMES="$NAMES step3"
  [ -f $CWD/profile.py ] && NAMES="$NAMES profile"

  for NAME in $NAMES; do
    local FILE=$CWD/$NAME
    local PART=$JOBID/$WORKDIR/$(echo $RELEASE | cut -d/ -f1)-$WORKFLOW-$NAME
    # upload the python configuration file, log, and nvprof results (if they exist)
    copy_if_exists ${FILE}.py      $LOCAL_DIR/${PART}.py
    copy_if_exists ${FILE}.log     $LOCAL_DIR/${PART}.log
    copy_if_exists ${FILE}.nvvp    $LOCAL_DIR/${PART}.nvvp
    copy_if_exists ${FILE}.profile $LOCAL_DIR/${PART}.profile
    if ! [ -f ${FILE}.log ]; then
      # if there is no log file, the workflow most likely did not run at all
      report "      - :x: [${NAME}.py]($UPLOAD_URL/${PART}.py): log, profile and summary are **missing**, see the full log for more information"
      continue
    fi
    local FLAG
    # check if the job was successful
    if [ -f ${FILE}.done ]; then
      FLAG=":heavy_check_mark:"
    else
      FLAG=":x:"
    fi
    # check for both profile and summary
    if [ -f ${FILE}.nvvp ] && [ -f ${FILE}.profile ]; then
      report "      - ${FLAG} [${NAME}.py]($UPLOAD_URL/${PART}.py): [log]($UPLOAD_URL/${PART}.log), [visual profile]($UPLOAD_URL/${PART}.nvvp) and [summary]($UPLOAD_URL/${PART}.profile)"
    elif [ -f ${FILE}.nvvp ]; then
      report "      - ${FLAG} [${NAME}.py]($UPLOAD_URL/${PART}.py): [log]($UPLOAD_URL/${PART}.log) and [visual profile]($UPLOAD_URL/${PART}.nvvp)"
    elif [ -f ${FILE}.profile ]; then
      report "      - ${FLAG} [${NAME}.py]($UPLOAD_URL/${PART}.py): [log]($UPLOAD_URL/${PART}.log) and [summary]($UPLOAD_URL/${PART}.profile)"
    else
      report "      - ${FLAG} [${NAME}.py]($UPLOAD_URL/${PART}.py): [log]($UPLOAD_URL/${PART}.log)"
    fi
    unset FLAG
  done

  # check for CUDA Compute Sanitizer
  if [ -f $CWD/sanitizer.py ]; then
    local PART=$JOBID/$WORKDIR/$(echo $RELEASE | cut -d/ -f1)-$WORKFLOW
    # initcheck
    copy_if_exists $CWD/initcheck.out $LOCAL_DIR/$PART-initcheck.out
    copy_if_exists $CWD/initcheck.log $LOCAL_DIR/$PART-initcheck.log
    if [ -f $CWD/tool-initcheck.done ]; then
      report "      - :heavy_check_mark: \`$SANITIZER_TOOL --tool initcheck $SYNCCHECK_OPTS\` ([report]($UPLOAD_URL/$PART-initcheck.out), [log]($UPLOAD_URL/$PART-initcheck.log)) did not find any errors"
    elif [ -f $CWD/tool-initcheck.fail ]; then
      local ERRORS="**some errors**"
      [ -f $CWD/initcheck.out ] && ERRORS="**$(echo $(tail -n1 $CWD/initcheck.out | cut -d: -f2 | sed -e's/========= No CUDA-MEMCHECK results found/no CUDA-MEMCHECK results/'))**"
      report "      - :x: \`$SANITIZER_TOOL --tool initcheck $SYNCCHECK_OPTS\` ([report]($UPLOAD_URL/$PART-initcheck.out), [log]($UPLOAD_URL/$PART-initcheck.log)) found $ERRORS"
      unset ERRORS
    else
      report "      - :warning: \`$SANITIZER_TOOL --tool initcheck $SYNCCHECK_OPTS\` did not run"
    fi
    # memcheck
    copy_if_exists $CWD/memcheck.out $LOCAL_DIR/$PART-memcheck.out
    copy_if_exists $CWD/memcheck.log $LOCAL_DIR/$PART-memcheck.log
    if [ -f $CWD/tool-memcheck.done ]; then
      report "      - :heavy_check_mark: \`$SANITIZER_TOOL --tool memcheck $MEMCHECK_OPTS\` ([report]($UPLOAD_URL/$PART-memcheck.out), [log]($UPLOAD_URL/$PART-memcheck.log)) did not find any errors"
    elif [ -f $CWD/tool-memcheck.fail ]; then
      local ERRORS="**some errors**"
      [ -f $CWD/memcheck.out ] && ERRORS="**$(echo $(tail -n1 $CWD/memcheck.out | cut -d: -f2 | sed -e's/========= No CUDA-MEMCHECK results found/no CUDA-MEMCHECK results/'))**"
      report "      - :x: \`$SANITIZER_TOOL --tool memcheck $MEMCHECK_OPTS\` ([report]($UPLOAD_URL/$PART-memcheck.out), [log]($UPLOAD_URL/$PART-memcheck.log)) found $ERRORS"
      unset ERRORS
    else
      report "      - :warning: \`$SANITIZER_TOOL --tool memcheck $MEMCHECK_OPTS\` did not run"
    fi
    # synccheck
    copy_if_exists $CWD/synccheck.out $LOCAL_DIR/$PART-synccheck.out
    copy_if_exists $CWD/synccheck.log $LOCAL_DIR/$PART-synccheck.log
    if [ -f $CWD/tool-synccheck.done ]; then
      report "      - :heavy_check_mark: \`$SANITIZER_TOOL --tool synccheck $SYNCCHECK_OPTS\` ([report]($UPLOAD_URL/$PART-synccheck.out), [log]($UPLOAD_URL/$PART-synccheck.log)) did not find any errors"
    elif [ -f $CWD/tool-synccheck.fail ]; then
      local ERRORS="**some errors**"
      [ -f $CWD/synccheck.out ] && ERRORS="**$(echo $(tail -n1 $CWD/synccheck.out | cut -d: -f2 | sed -e's/========= No CUDA-MEMCHECK results found/no CUDA-MEMCHECK results/'))**"
      report "      - :x: \`$SANITIZER_TOOL --tool synccheck $SYNCCHECK_OPTS\` ([report]($UPLOAD_URL/$PART-synccheck.out), [log]($UPLOAD_URL/$PART-synccheck.log)) found $ERRORS"
      unset ERRORS
    else
      report "      - :warning: \`$SANITIZER_TOOL --tool synccheck $SYNCCHECK_OPTS\` did not run"
    fi
  fi
}

# Upload nvprof profiles
#
# Usage:
#   upload_profiles RELEASE [RELEASE ...]
#
function upload_profiles() {
  [ "$1" ] || return 1
  local -a RELEASES=("$@")

  report "## logs and \`nvprof\`/\`nvvp\` profiles"

  local SAMPLE
  for SAMPLE in $SAMPLES $DATA_SAMPLES; do
    local DATASET=${!SAMPLE}
    report "#### $DATASET"
    local WORKDIR=$(echo $DATASET | cut -d/ -f 2-3 --output-delimiter=-)

    # all releases and workflows
    local RELEASE
    for RELEASE in ${RELEASES[@]}; do
      local WORKFLOW
      for WORKFLOW in $WORKFLOWS $DATA_WORKFLOWS; do
        upload_artefacts $RELEASE $WORKDIR $WORKFLOW
      done
    done
    report
  done
}

# Upload the log file
#
# Usage:
#   upload_log_files RELEASE [RELEASE ...]
#
# Note: the releases are used to build the hash of the upload area
#
function upload_log_files() {
  [ "$1" ] || return 1
  local -a RELEASES=("$@")

  cp $BASE/log $LOCAL_DIR/$JOBID/log
  report "## Logs"
  report "The full log is available at $UPLOAD_URL/$JOBID/log ."
}
