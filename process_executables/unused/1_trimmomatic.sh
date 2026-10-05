#!/bin/bash

#SBATCH --job-name=trimmomatic            ## Name of the job.
#SBATCH -A JMARTINY_LAB             ## Account to charge; personal or lab
#SBATCH -p standard                 ## Partition/queue name
#SBATCH --nodes=1                   ## (-N) number of nodes the job will use
#SBATCH --ntasks=1                  ## (-n) number of processes to be launched
#SBATCH --cpus-per-task=4           ## number of cores the jobs needs
#SBATCH -o trimmomatic_%j.out          ## File to which STDOUT will be written, %j inserts jobid
#SBATCH -e trimmomatic_%j.err          ## File to which STDERR will be written, %j inserts jobid
#SBATCH --array=1-184                ## This value (1-184) depends on the number of samples (1-no. of samples)



export BASE=/dfs5/bio/abarrons/CA_curto
export WD=$BASE/mg/raw_seqs
export PROGRAM_PATH=/opt/apps/trimmomatic/0.39


#go to working directory
cd $WD

## Set environmental variables for an array job
SAMPLE_NAME=`ls *READ1-Sequences.txt.gz | head -n $SLURM_ARRAY_TASK_ID | tail -n 1`
PREFIX=`basename $SAMPLE_NAME READ1-Sequences.txt.gz` ;

#submit job


java -jar $PROGRAM_PATH/trimmomatic-0.39.jar \
 PE \
 -phred33 \
 -trimlog $WD/${PREFIX}logfile \
 ${PREFIX}READ1-Sequences.txt.gz \
 ${PREFIX}READ2-Sequences.txt.gz \
 ${PREFIX}READ1-paired.txt.gz \
 ${PREFIX}READ1-unpaired.txt.gz \
 ${PREFIX}READ2-paired.txt.gz \
 ${PREFIX}READ2-unpaired.txt.gz \
 ILLUMINACLIP:$PROGRAM_PATH/adapters/TruSeq2-PE.fa:2:30:10:2:keepBothReads \
 LEADING:3 \
 TRAILING:3 \
 SLIDINGWINDOW:4:15 \
 MINLEN:36
