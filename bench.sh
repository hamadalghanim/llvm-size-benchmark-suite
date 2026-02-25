#!/usr/bin/env bash
set -uo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
BENCHMARK_DIR="${1:-/workspace/build/benchmarks}"
PLUGIN="/workspace/LLVMNextFM.so"
IR2VEC_VOCAB="/workspace/vocab.json"
OPT="${OPT:-opt}"
OUTPUT_DIR="/workspace/results"
PASSES_LOG="$OUTPUT_DIR/results.tsv"

LLC="${LLC:-llc}"
LLVM_SIZE="${LLVM_SIZE:-llvm-size}"

mkdir -p "$OUTPUT_DIR"

# ── Header ────────────────────────────────────────────────────────────────────
printf "benchmark\tpass\ttext_before\ttext_after\treduction_pct\ttime_s\tstatus\n" | tee "$PASSES_LOG"

# ── Helper: compile .bc -> .o and return text section size via llvm-size ──────
obj_size() {
    local bc="$1"
    local obj="${bc%.bc}.o"
    "$LLC" -filetype=obj "$bc" -o "$obj" 2>&1 || { echo "0"; return 1; }
    # llvm-size output: text data bss dec hex filename
    "$LLVM_SIZE" "$obj" 2>/dev/null | awk 'NR==2 {print $1}'
}

# ── Helper: run opt with a pass and measure time ──────────────────────────────
run_pass() {
    local input="$1"
    local output="$2"
    local pass_args=("${@:3}")

    local start end elapsed rc
    start=$(date +%s%3N)
    "$OPT" "${pass_args[@]}" "$input" -o "$output"
    rc=$?
    end=$(date +%s%3N)
    elapsed=$(echo "scale=3; ($end - $start) / 1000" | bc)
    echo "$elapsed $rc"
}

# ── Run one benchmark file through both passes ────────────────────────────────
run_benchmark() {
    local bc_file="$1"
    local name
    name=$(echo "$bc_file" | sed "s|$BENCHMARK_DIR/||" | sed 's|/|_|g' | sed 's|\.bc$||')

    # Compile baseline (no pass) to get before sizes
    echo "  [baseline] compiling $name..." >&2
    local baseline_bc="$OUTPUT_DIR/${name}_baseline.bc"
    cp "$bc_file" "$baseline_bc"
    local text_before
    text_before=$(obj_size "$baseline_bc")

    # ── Pass 1: FM (func-merging + f3m) ──────────────────────────────────────
    echo "  [FM] running on $name..." >&2
    local fm_out="$OUTPUT_DIR/${name}_fm.bc"
    local fm_result
    fm_result=$(run_pass "$bc_file" "$fm_out" \
        -load-pass-plugin="$PLUGIN" \
        -load="$PLUGIN" \
        -passes="default<Oz>,func-merging" \
        --func-merging-whole-program \
        --func-merging-f3m)
    local fm_time fm_rc fm_text fm_reduction fm_status
    fm_time=$(echo "$fm_result" | awk '{print $1}')
    fm_rc=$(echo "$fm_result" | awk '{print $2}')
    if [[ "$fm_rc" -eq 0 && -f "$fm_out" ]]; then
        fm_text=$(obj_size "$fm_out")
        fm_reduction=$(echo "scale=2; 100 * (1 - $fm_text / $text_before)" | bc)
        fm_status="ok"
    else
        fm_text="N/A"; fm_reduction="N/A"; fm_status="FAILED"
    fi


    printf "%s\tFM\t%s\t%s\t%s\t%s\t%s\n" \
        "$name" "$text_before" "$fm_text" "$fm_reduction" "$fm_time" "$fm_status" \
        | tee -a "$PASSES_LOG"

    # ── Pass 2: FM (func-merging + f3m) ──────────────────────────────────────
    echo "  [FM-Linear] running on $name..." >&2
    local fml_out="$OUTPUT_DIR/${name}_fm_linear.bc"
    local fm_result
    fm_result=$(run_pass "$bc_file" "$fml_out" \
        -load-pass-plugin="$PLUGIN" \
        -load="$PLUGIN" \
        -passes="default<Oz>,func-merging" \
        --func-merging-whole-program)
    local fm_time fm_rc fm_text fm_reduction fm_status
    fm_time=$(echo "$fm_result" | awk '{print $1}')
    fm_rc=$(echo "$fm_result" | awk '{print $2}')
    if [[ "$fm_rc" -eq 0 && -f "$fml_out" ]]; then
        fm_text=$(obj_size "$fml_out")
        fm_reduction=$(echo "scale=2; 100 * (1 - $fm_text / $text_before)" | bc)
        fm_status="ok"
    else
        fm_text="N/A"; fm_reduction="N/A"; fm_status="FAILED"
    fi


    printf "%s\tFM-Linear\t%s\t%s\t%s\t%s\t%s\n" \
        "$name" "$text_before" "$fm_text" "$fm_reduction" "$fm_time" "$fm_status" \
        | tee -a "$PASSES_LOG"


    # ── Pass 3: IR2Vec ────────────────────────────────────────────────────────
    echo "  [IR2Vec] running on $name..." >&2
    local ir2vec_out="$OUTPUT_DIR/${name}_ir2vec.bc"
    local ir2vec_result
    ir2vec_result=$(run_pass "$bc_file" "$ir2vec_out" \
        -load-pass-plugin="$PLUGIN" \
        -load="$PLUGIN" \
        -passes="default<Oz>,func-merging" \
        --func-merging-whole-program \
        --func-merging-ir2vec \
        --ir2vec-vocab-path "$IR2VEC_VOCAB")
    local ir2vec_time ir2vec_rc ir2vec_text ir2vec_reduction ir2vec_status
    ir2vec_time=$(echo "$ir2vec_result" | awk '{print $1}')
    ir2vec_rc=$(echo "$ir2vec_result" | awk '{print $2}')
    if [[ "$ir2vec_rc" -eq 0 && -f "$ir2vec_out" ]]; then
        ir2vec_text=$(obj_size "$ir2vec_out")
        ir2vec_reduction=$(echo "scale=2; 100 * (1 - $ir2vec_text / $text_before)" | bc)
        ir2vec_status="ok"
    else
        ir2vec_text="N/A"; ir2vec_reduction="N/A"; ir2vec_status="FAILED"
    fi

    printf "%s\tIR2Vec\t%s\t%s\t%s\t%s\t%s\n" \
        "$name" "$text_before" "$ir2vec_text" "$ir2vec_reduction" "$ir2vec_time" "$ir2vec_status" \
        | tee -a "$PASSES_LOG"
}

# ── Main: iterate over all .bc files ─────────────────────────────────────────
found=0
while IFS= read -r -d '' bc_file; do
    echo "── Processing: $bc_file" >&2
    run_benchmark "$bc_file"
    ((found++))
done < <(find "$BENCHMARK_DIR" -name "*.bc" -print0 | sort -z)

echo "" >&2
echo "Done. Processed $found files. Results saved to $PASSES_LOG" >&2