#!/bin/bash

# =================================================================
# Configuration Variables
# =================================================================
SUITE_PATH="/workspace/build/benchmarks/"
PASS_PLUGIN="/workspace/LLVMNextFM.so"
IR2VEC_VOCAB="/workspace/vocab.json"

RESULTS_DIR="/workspace/build/results"
ARTIFACTS_DIR="/workspace/build/artifacts"

# Ensure output directories exist before running anything
mkdir -p "$RESULTS_DIR"
mkdir -p "$ARTIFACTS_DIR/baseline"
mkdir -p "$ARTIFACTS_DIR/f3m"
mkdir -p "$ARTIFACTS_DIR/ir2vec"

# The base command used across all runs
BASE_CMD="python3 ./main.py --suite-path $SUITE_PATH --reporter markdown --verbose"

# =================================================================
# Phase 1: Compilation Benchmarks
# =================================================================

# echo "Starting RUN 1: Baseline (No Custom Pass)"
# $BASE_CMD \
#   --output-dir "$ARTIFACTS_DIR/baseline" > "$RESULTS_DIR/baseline_results.md"

echo "Starting RUN 2: Function Merging (F3M)"
$BASE_CMD \
  --pass-plugin "$PASS_PLUGIN" \
  --output-dir "$ARTIFACTS_DIR/f3m" \
  -Xopt=-passes="default<Oz>,func-merging" \
  -Xopt=--func-merging-whole-program \
  -Xopt=--func-merging-f3m > "$RESULTS_DIR/f3m_results.md"

echo "Starting RUN 3: Function Merging (IR2Vec)"
$BASE_CMD \
  --pass-plugin "$PASS_PLUGIN" \
  --output-dir "$ARTIFACTS_DIR/ir2vec" \
  -Xopt=-passes="default<Oz>,func-merging" \
  -Xopt=--func-merging-whole-program \
  -Xopt=--func-merging-ir2vec \
  -Xopt=--ir2vec-vocab-path \
  -Xopt="$IR2VEC_VOCAB" > "$RESULTS_DIR/ir2vec_results.md"


# =================================================================
# Phase 2: Generating Plots
# =================================================================
echo ""
echo "Generating plots from compilation artifacts..."

# Plot 1: Object Size Reduction (Requires Baseline)
python3 ../plot.py \
  "$ARTIFACTS_DIR/f3m" \
  "$ARTIFACTS_DIR/ir2vec" \
  --baseline "$ARTIFACTS_DIR/baseline" \
  --target objsize \
  -o "$RESULTS_DIR/size_reduction_plot.png"
echo "-> Created: $RESULTS_DIR/size_reduction_plot.png"

# Plot 2: Total Merge Counts
python3 ../plot.py \
  "$ARTIFACTS_DIR/f3m" \
  "$ARTIFACTS_DIR/ir2vec" \
  --target mergecount \
  -o "$RESULTS_DIR/merge_count_plot.png"
echo "-> Created: $RESULTS_DIR/merge_count_plot.png"

# Plot 3: 3-Way Merge Counts
python3 ../plot.py \
  "$ARTIFACTS_DIR/f3m" \
  "$ARTIFACTS_DIR/ir2vec" \
  --target mergecount3 \
  -o "$RESULTS_DIR/3way_merge_plot.png"
echo "-> Created: $RESULTS_DIR/3way_merge_plot.png"

echo ""
echo "Experiment complete! All Markdown tables and PNG plots are saved in $RESULTS_DIR."