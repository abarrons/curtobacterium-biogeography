#!/bin/bash

#SBATCH --job-name=hs-blast           ## Name of the job.
#SBATCH -A JMARTINY_LAB                 ## Account to charge; personal or lab
#SBATCH -p standard                 ## Partition/queue name
#SBATCH --nodes=1                   ## (-N) number of nodes the job will use
#SBATCH --time=24:00:00
#SBATCH --mem-per-cpu=4GB
#SBATCH --cpus-per-task=16           ## number of CPUs to be used per task
#SBATCH -o %x.%A.%a.out             ## File to which STDOUT will be written, %j inserts jobid
#SBATCH -e %x.%A.%a.err             ## File to which STDERR will be written, %j inserts jobid
#SBATCH --array=1-31                ## This value (1-184) depends on the number of samples (.sam files)

## Set environmental variables

BASE=/dfs5/bio/abarrons/CA_curto/mg
WD=$BASE/filtered_seqs_new
BLASTDB=/dfs5/bio/abarrons/CA_curto/curto_core_genesDB/referenceDB/total_coregenes.fna
PROGRAM_PATH=/dfs5/bio/abarrons/programs/queries/Linux-amd64/bin
OUTDIR=$BASE/blast_out_e50_new
THREADS=16

# Check if this is the first task
if [[ "$SLURM_ARRAY_TASK_ID" -eq 1 ]]; then

  # make a clean up of the folder and create output directories
  rm -rf $OUTDIR
  mkdir $OUTDIR
  rm -rf $WD/hbndb
fi

# Check if task ID is 2 or larger and introduce a delay
if [[ "$SLURM_ARRAY_TASK_ID" -ge 2 ]]; then
  sleep 20
fi

## Go to working directory
cd $WD

## Set environmental variables specific for the job
INFILE=`ls *.filter.total.fa | head -n $SLURM_ARRAY_TASK_ID | tail -n 1`
echo "$INFILE"
PREFIX=$(echo $INFILE | cut -d "." -f1);

## Job
$PROGRAM_PATH/hs-blastn \
  -outfmt 6 -evalue 1e-50 -num_threads $THREADS -db_dir ${PREFIX} \
  -max_hsps 1 -subject_besthit -max_target_seqs 1 \
  $INFILE $BLASTDB > $OUTDIR/${PREFIX}.blast.txt
