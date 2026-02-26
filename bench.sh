#!/usr/bin/env bash
set -uo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
BENCHMARK_DIR="${1:-/workspace/build/benchmarks}"
PLUGIN="/workspace/LLVMNextFM.so"
IR2VEC_VOCAB="/workspace/vocab.json"
OPT="${OPT:-opt}"
OUTPUT_DIR="/workspace/results"

LLC="${LLC:-llc}"
LLVM_SIZE="${LLVM_SIZE:-llvm-size}"

SIZE_CSV="$OUTPUT_DIR/size.csv"
PERF_CSV="$OUTPUT_DIR/perf.csv"

mkdir -p "$OUTPUT_DIR"

# ── GNU time (Ubuntu: apt install time if missing) ────────────────────────────
TIME_CMD="/usr/bin/time"
TIME_FMT="%e %M"   # elapsed wall-clock seconds, peak RSS in KB

# ── CSV headers ───────────────────────────────────────────────────────────────
printf "program_name,pass_name,size\n"              > "$SIZE_CSV"
printf "program_name,pass_name,time_s,memory_kb\n"  > "$PERF_CSV"

# ── Helper: compile .bc -> .o, return text section size ───────────────────────
obj_size() {
    local bc="$1"
    local obj="${bc%.bc}.o"
    "$LLC" -filetype=obj "$bc" -o "$obj" 2>/dev/null || { echo "0"; return 1; }
    "$LLVM_SIZE" "$obj" 2>/dev/null | awk 'NR==2 {print $1}'
}

# ── Helper: run opt, return "<elapsed_s> <peak_kb> <exit_code>" ───────────────
run_pass() {
    local input="$1"
    local output="$2"
    local pass_args=("${@:3}")

    local time_out
    time_out=$(mktemp)

    "$TIME_CMD" -f "$TIME_FMT" -o "$time_out" \
        "$OPT" "${pass_args[@]}" "$input" -o "$output" 2>/dev/null
    local rc=$?

    local elapsed peak_kb
    elapsed=$(awk '{print $1}' "$time_out")
    peak_kb=$(awk '{print $2}' "$time_out")
    rm -f "$time_out"

    echo "$elapsed $peak_kb $rc"
}

# ── Run one benchmark through all passes ──────────────────────────────────────
run_benchmark() {
    local bc_file="$1"
    local name
    name=$(echo "$bc_file" | sed "s|$BENCHMARK_DIR/||" | sed 's|/|_|g' | sed 's|\.bc$||')

    # ── Helper: run one pass and append to both CSVs ──────────────────────────
    emit() {
        local label="$1" out_bc="$2"; shift 2
        local pass_args=("$@")

        echo "  [$label] $name" >&2
        local result elapsed peak_kb rc
        result=$(run_pass "$bc_file" "$out_bc" "${pass_args[@]}")
        elapsed=$(echo "$result" | awk '{print $1}')
        peak_kb=$(echo "$result" | awk '{print $2}')
        rc=$(echo "$result"      | awk '{print $3}')

        if [[ "$rc" -eq 0 && -f "$out_bc" ]]; then
            local size
            size=$(obj_size "$out_bc")
            printf "%s,%s,%s\n"      "$name" "$label" "$size"               >> "$SIZE_CSV"
            printf "%s,%s,%s,%s\n"   "$name" "$label" "$elapsed" "$peak_kb" >> "$PERF_CSV"
        else
            printf "%s,%s,FAILED\n"        "$name" "$label"                 >> "$SIZE_CSV"
            printf "%s,%s,FAILED,FAILED\n" "$name" "$label"                 >> "$PERF_CSV"
        fi
    }

    # ── Baseline: default<Oz> only, no func-merging ───────────────────────────
    emit "baseline" "$OUTPUT_DIR/${name}_baseline.bc" \
        -passes="default<Oz>"

    # ── Pass 1: FM (func-merging + f3m) ───────────────────────────────────────
    emit "fm-f3m" "$OUTPUT_DIR/${name}_fm.bc" \
        -load-pass-plugin="$PLUGIN" \
        -load="$PLUGIN" \
        -passes="default<Oz>,func-merging" \
        --func-merging-whole-program \
        --func-merging-f3m

    # ── Pass 2: FM-Linear (no f3m) ────────────────────────────────────────────
    emit "fm" "$OUTPUT_DIR/${name}_fm_linear.bc" \
        -load-pass-plugin="$PLUGIN" \
        -load="$PLUGIN" \
        -passes="default<Oz>,func-merging" \
        --func-merging-whole-program

    # ── Pass 3: IR2Vec ────────────────────────────────────────────────────────
    emit "fm-ir2vec" "$OUTPUT_DIR/${name}_ir2vec.bc" \
        -load-pass-plugin="$PLUGIN" \
        -load="$PLUGIN" \
        -passes="default<Oz>,func-merging" \
        --func-merging-whole-program \
        --func-merging-ir2vec \
        --ir2vec-vocab-path "$IR2VEC_VOCAB"
}

# ── Main ──────────────────────────────────────────────────────────────────────
found=0
while IFS= read -r -d '' bc_file; do
    echo "── Processing: $bc_file" >&2
    run_benchmark "$bc_file"
    ((found++))
done < <(find "$BENCHMARK_DIR" -name "*.bc" -print0 | sort -z)

echo "" >&2
echo "Done. Processed $found files." >&2
echo "  Size CSV : $SIZE_CSV" >&2
echo "  Perf CSV : $PERF_CSV" >&2