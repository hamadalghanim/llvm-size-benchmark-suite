#!/usr/bin/env bash
set -uo pipefail

OUTPUT_DIR="${1:-/workspace/results}"
PASSES_LOG="$OUTPUT_DIR/results_reconstructed.tsv"
LLVM_SIZE="${LLVM_SIZE:-llvm-size}"
LLC="${LLC:-llc}"

mkdir -p "$OUTPUT_DIR"

obj_size() {
    local bc="$1"
    local obj="${bc%.bc}.o"
    "$LLC" -filetype=obj "$bc" -o "$obj" 2>/dev/null || { echo "0"; return 1; }
    "$LLVM_SIZE" "$obj" 2>/dev/null | awk 'NR==2 {print $1}'
}

printf "benchmark\tpass\ttext_before\ttext_after\treduction_pct\ttime_s\tstatus\n" | tee "$PASSES_LOG"

mod_ms() {
    python3 -c "import os; print(int(os.path.getmtime('$1') * 1000))"
}

for baseline in "$OUTPUT_DIR"/*_baseline.bc; do
    name=$(basename "$baseline" _baseline.bc)

    fm_out="$OUTPUT_DIR/${name}_fm.bc"
    ir2vec_out="$OUTPUT_DIR/${name}_ir2vec.bc"

    text_before=$(obj_size "$baseline")

    # ── FM timing: baseline -> fm ─────────────────────────────────────────────
    if [[ -f "$fm_out" ]]; then
        t_start=$(mod_ms "$baseline")
        t_end=$(mod_ms "$fm_out")
        fm_time=$(echo "scale=3; ($t_end - $t_start) / 1000" | bc)
        fm_text=$(obj_size "$fm_out")
        fm_reduction=$(echo "scale=2; 100 * (1 - $fm_text / $text_before)" | bc)
        fm_status="ok"
    else
        fm_time="N/A"; fm_text="N/A"; fm_reduction="N/A"; fm_status="MISSING"
    fi

    printf "%s\tFM\t%s\t%s\t%s\t%s\t%s\n" \
        "$name" "$text_before" "$fm_text" "$fm_reduction" "$fm_time" "$fm_status" \
        | tee -a "$PASSES_LOG"

    # ── IR2Vec timing: fm -> ir2vec ───────────────────────────────────────────
    if [[ -f "$ir2vec_out" && -f "$fm_out" ]]; then
        t_start=$(mod_ms "$fm_out")
        t_end=$(mod_ms "$ir2vec_out")
        ir2vec_time=$(echo "scale=3; ($t_end - $t_start) / 1000" | bc)
        ir2vec_text=$(obj_size "$ir2vec_out")
        ir2vec_reduction=$(echo "scale=2; 100 * (1 - $ir2vec_text / $text_before)" | bc)
        ir2vec_status="ok"
    else
        ir2vec_time="N/A"; ir2vec_text="N/A"; ir2vec_reduction="N/A"; ir2vec_status="MISSING"
    fi

    printf "%s\tIR2Vec\t%s\t%s\t%s\t%s\t%s\n" \
        "$name" "$text_before" "$ir2vec_text" "$ir2vec_reduction" "$ir2vec_time" "$ir2vec_status" \
        | tee -a "$PASSES_LOG"
done

echo "Done. Results saved to $PASSES_LOG" >&2