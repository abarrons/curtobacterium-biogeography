#!/bin/bash

#SBATCH --job-name=bbmerge-prodigal          ## Name of the job.
#SBATCH -A JMARTINY_LAB                 ## Account to charge; personal or lab
#SBATCH -p standard                 ## Partition/queue name
#SBATCH --time=12:00:00
#SBATCH --nodes=1                   ## (-N) number of nodes the job will use
#SBATCH --mem=64GB                  ## number of OpenMP threads - total RAM request = 4 * 4.5GB/core = 18G
#SBATCH --cpus-per-task=8          ## number of CPUs to be used per task
#SBATCH -o bbmerge-prodigal_%j.out          ## File to which STDOUT will be written, %j inserts jobid
#SBATCH -e bbmerge-prodigal_%j.err          ## File to which STDERR will be written, %j inserts jobid
#SBATCH --array=1-184                ## This value (1-184) depends on the number of samples i.e. 1-num. samples


## Set environmental variables
export BASE=/dfs5/bio/abarrons/CA_curto/mg
export WD=$BASE/filtered_seqs_grass-fungi

## Load programs: BBMap and prodigal
module load bbmap/38.87
module load prodigal/2.6.3

## Go to working directory and make folder for output files
cd $WD
mkdir $WD/merged_seqs
mkdir $BASE/prodigal_out


## Set environmental variables specific for the job
INFILE=`ls *_R1_GrassAndFungi_filtered.fastq.gz | head -n $SLURM_ARRAY_TASK_ID | tail -n 1`
PREFIX=`basename $INFILE _R1_GrassAndFungi_filtered.fastq.gz` ;
SAMPLEID=$(echo ${INFILE} | cut -f 4-6 -d "-")

## Job: this will merge R1 and R2 files to get longer reads
bbmerge-auto.sh k=60 \
in1=${PREFIX}_R1_GrassAndFungi_filtered.fastq.gz \
in2=${PREFIX}_R2_GrassAndFungi_filtered.fastq.gz \
out=$WD/merged_seqs/${SAMPLEID}_merged_reads.fasta \
outu1=$WD/merged_seqs/${SAMPLEID}_unmerged1.fastq.gz \
outu2=$WD/merged_seqs/${SAMPLEID}_unmerged2.fastq.gz

## Job: reformat unmerged R1 fastq files to fasta files
reformat.sh \
in=$WD/merged_seqs/${SAMPLEID}_unmerged1.fastq.gz \
out=$WD/merged_seqs/${SAMPLEID}_unmerged1.fasta

cd $WD/merged_seqs

## This script will concatenate merged and unmerged fasta files into a single file per sample
cat ${SAMPLEID}_merged_reads.fasta ${SAMPLEID}_unmerged1.fasta > $SAMPLEID.filter.total.fa

## Prodigal will translate nucleotide sequences to protein sequences for subsequent analysis
prodigal \
  -a $BASE/prodigal_out/${SAMPLEID}.aa.seqs.fa \
  -f gff \
  -i $SAMPLEID.filter.total.fa \
  -p meta > $BASE/prodigal_out/$SAMPLEID.gff

## clean: remove intermediary files
rm -f $BASE/prodigal_out/${SAMPLEID}.gff
rm -f ${SAMPLEID}_merged_reads.fasta
rm -f ${SAMPLEID}_unmerged*.fastq.gz
rm -f ${SAMPLEID}_unmerged1.fasta
rm -f $SAMPLEID.filter.total.fa
