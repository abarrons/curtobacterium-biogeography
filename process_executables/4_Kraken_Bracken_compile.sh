#!/bin/bash
#SBATCH --job-name=k2_bracken_1sample
#SBATCH -A JMARTINY_LAB
#SBATCH -p hugemem
#SBATCH --nodes=1
#SBATCH --time=36:00:00
#SBATCH --cpus-per-task=40
#SBATCH --mem=720G
#SBATCH --array=1-188%4
#SBATCH -o %x.%A.%a.out
#SBATCH -e %x.%A.%a.err
#SBATCH --mail-user=abarrons@uci.edu
#SBATCH --mail-type=END,FAIL

set -euo pipefail

module load kraken2/2.1.2
module load bracken/2.6.2
module load python/2.7.17

BASE=/dfs10/bio/abarrons/CA_curto/mg
READS_DIR=$BASE/filtered_seqs
KRAKEN_DIR=$BASE/kraken2_out
BRACKEN_DIR=$KRAKEN_DIR/bracken_out

DB_NET="/dfs10/bio/abarrons/KrakenGTDB_core"
PROGRAM_PATH=/opt/apps/bracken/2.6.2/bin/
THREADS="${SLURM_CPUS_PER_TASK}"

mkdir -p "$KRAKEN_DIR" "$BRACKEN_DIR"

echo "Host: $(hostname)"
echo "TMPDIR=${TMPDIR:-/tmp}"
df -h "${TMPDIR:-/tmp}" || true

# Stable list of inputs
mapfile -t ALL < <(cd "$READS_DIR" && ls -1 *.filter.total.fa | LC_ALL=C sort)
N=${#ALL[@]}
echo "Total input files: $N"

if (( N != 188 )); then
  echo "ERROR: expected 188 input files, found $N"
  exit 1
fi

IDX=$((SLURM_ARRAY_TASK_ID - 1))
if (( IDX < 0 || IDX >= N )); then
  echo "Task ${SLURM_ARRAY_TASK_ID} out of range (idx=$IDX, N=$N). Exiting."
  exit 0
fi

INFILE="${ALL[$IDX]}"
PREFIX="${INFILE%.filter.total.fa}"

# Kraken outputs
K_REPORT="$KRAKEN_DIR/${PREFIX}.report.txt"

# Bracken outputs
B_OUT="$BRACKEN_DIR/${PREFIX}.bracken"
B_REPORT="$BRACKEN_DIR/${PREFIX}.bracken.report.txt"

# Restart-safe skip: if bracken exists, we consider the whole pipeline done
if [[ -s "$B_OUT" && -s "$B_REPORT" ]]; then
  echo "Already done (bracken outputs exist): $PREFIX"
  exit 0
fi

# Stage reads to local
echo "Staging input to local scratch..."
cp -v "$READS_DIR/$INFILE" "${TMPDIR}/${INFILE}"

# ---------- Kraken2 ----------
TMP_K_REPORT="${TMPDIR}/${PREFIX}.report.txt"
TMP_K_OUT="${TMPDIR}/${PREFIX}.out"

if [[ ! -s "$K_REPORT" ]]; then
  echo "[$(date)] START kraken2 $INFILE"
  kraken2 \
    --threads "$THREADS" \
    --db "$DB_NET" \
    --report-zero-counts \
    --report "$TMP_K_REPORT" \
    "${TMPDIR}/${INFILE}" > /dev/null
  echo "[$(date)] END   kraken2 $INFILE"

  mv -f "$TMP_K_REPORT" "$K_REPORT"

else
  echo "Kraken outputs already exist for $PREFIX; skipping kraken2."
fi

# ---------- Bracken ----------
TMP_B_OUT="${TMPDIR}/${PREFIX}.bracken"
TMP_B_REPORT="${TMPDIR}/${PREFIX}.bracken.report.txt"

if [[ ! -s "$B_OUT" || ! -s "$B_REPORT" ]]; then
  echo "[$(date)] START bracken $PREFIX"
  python "$PROGRAM_PATH/est_abundance.py" \
    -i "$K_REPORT" \
    -k "$DB_NET/database150mers.kmer_distrib" \
    -o "$TMP_B_OUT" \
    --out-report "$TMP_B_REPORT" \
    -l G \
    -t 10
  echo "[$(date)] END   bracken $PREFIX"

  mv -f "$TMP_B_REPORT" "$B_REPORT"
  mv -f "$TMP_B_OUT" "$B_OUT"
else
  echo "Bracken outputs already exist for $PREFIX; skipping bracken."
fi

echo "Done: $PREFIX"
ls -lh "$K_REPORT" "$B_REPORT" "$B_OUT" || true


   # print end of process messages
now=$(date)
echo "Job finished at: $now"
