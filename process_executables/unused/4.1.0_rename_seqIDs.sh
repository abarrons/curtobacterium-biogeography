#!/bin/bash

#SBATCH --job-name=seqkit_rename  ## Name of the job.
#SBATCH -A JMARTINY_LAB                ## Account to charge; personal or lab
#SBATCH -p standard                    ## Partition/queue name
#SBATCH --time=2:00:00
#SBATCH --nodes=1                      ## (-N) number of nodes the job will use
#SBATCH --mem-per-cpu=4GB
#SBATCH --cpus-per-task=2              ## number of CPUs to be used per task
#SBATCH -o %x.%A.%a.out             ## File to which STDOUT will be written, %j inserts jobid
#SBATCH -e %x.%A.%a.err             ## File to which STDERR will be written, %j inserts jobid
#SBATCH --array=1-188                ## This value (1-184) depends on the number of samples (.sam files)


## Set environmental variables

BASE=/dfs5/bio/abarrons/CA_curto/mg
WD=$BASE/filtered_seqs
PROGRAM_PATH=/dfs5/bio/abarrons/programs
THREADS=2

cd $WD


## Set environmental variables specific for the job
INFILE=`ls *.filter.total.fa | head -n $SLURM_ARRAY_TASK_ID | tail -n 1`
echo "$INFILE"
PREFIX=$(echo $INFILE | cut -d "." -f1);

RENAMED_FILE="${PREFIX}.filter.total.renamed.fa"

echo "Processing file: $INFILE"
echo "Renamed output: $RENAMED_FILE"

$PROGRAM_PATH/seqkit rename $INFILE -o $RENAMED_FILE  -n -j $THREADS
