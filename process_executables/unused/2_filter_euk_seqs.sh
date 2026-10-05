#!/bin/bash

#SBATCH --job-name=filter_grass_fungi  ## Name of the job.
#SBATCH -A JMARTINY_LAB             ## Account to charge; personal or lab
#SBATCH -p standard                 ## Partition/queue name
#SBATCH --time=12:00:00
#SBATCH --nodes=1                   ## (-N) number of nodes the job will use
#SBATCH --mem=18GB                  ## number of OpenMP threads - total RAM request = 4 * 4.5GB/core = 18G
#SBATCH --cpus-per-task=16          ## number of CPUs to be used per task
#SBATCH -o filter_grass_fungi_%j.out          ## File to which STDOUT will be written, %j inserts jobid
#SBATCH -e filter_grass_fungi_%j.err          ## File to which STDERR will be written, %j inserts jobid
#SBATCH --array=1-184                ## This value (1-184) depends on the number of samples (.sam files)



## Set environmental variables
export BASE=/dfs5/bio/abarrons/CA_curto
export WD=$BASE/mg/raw_seqs
export REFGENOMES_PATH=/dfs5/bio/abarrons/ref_genomes

## Load programs: BWA and samtools
module load samtools/1.10
module load bwa/0.7.17

## Go to working directory and make folders for output files
cd $WD
mkdir $BASE/filtered_seqs_grass-fungi
mkdir $BASE/filtered_seqs_grass-fungi/singletons

## Set environmental variables specific for an array the job
SAMPLE_NAME=`ls *READ1-paired.txt.gz | head -n $SLURM_ARRAY_TASK_ID | tail -n 1`
PREFIX=`basename $SAMPLE_NAME READ1-paired.txt.gz` ;

## Align against reference genome of Grass (Lolium perenne) to remove eukaryotic sequences
## using BWA and then samtools to ransform .sam files to .bam
## and then filter unmaped sequences and return
## only unmaped sequences into fwd (R1) and rev (R2) fastq files
## Job:
## bwa mem maps reads to reference genome
## samtools view transforms .sam file to. bam and filters out maped reads
## samtools fastq will give you the R1 and R2 fastq files

bwa mem \
    -t 16 \
    $REFGENOMES_PATH/GCA_001735685.1_ASM173568v1_genomic.fna \
    ${SAMPLE_NAME} \
    ${PREFIX}READ2-paired.txt.gz \
    | samtools view -@ 16 -bhS -f 0x4 \
    | samtools fastq -@ 16 -n -c 5 \
    -s $BASE/filtered_seqs_grass-fungi/singletons/${PREFIX}_singleton_grass.fastq.gz \
    -1 $BASE/filtered_seqs_grass-fungi/${PREFIX}_R1_Grass_filtered.fastq.gz \
    -2 $BASE/filtered_seqs_grass-fungi/${PREFIX}_R2_Grass_filtered.fastq.gz

## Align against reference genome of fungus (Pyrenophora teres) to remove eukaryotic sequences
## using BWA and then samtools to ransform .sam files to .bam
## and then filter unmaped sequences and return
## only unmaped sequences into fwd (R1) and rev (R2) fastq files
## Job:
## bwa mem maps reads to reference genome
## samtools view transforms .sam file to. bam and filters out maped reads
## samtools fastq will give you the R1 and R2 fastq files
bwa mem \
    -t 16 \
    $REFGENOMES_PATH/GCA_008086845.1_ASM808684v1_genomic.fna \
    $BASE/filtered_seqs_grass-fungi/${PREFIX}_R1_Grass_filtered.fastq.gz \
    $BASE/filtered_seqs_grass-fungi/${PREFIX}_R2_Grass_filtered.fastq.gz \
    | samtools view -@ 16 -bhS -f 0x4 \
    | samtools fastq -@ 16 -n -c 5 \
    -s $BASE/filtered_seqs_grass-fungi/singletons/${PREFIX}_singleton_grass.fastq.gz \
    -1 $BASE/filtered_seqs_grass-fungi/${PREFIX}_R1_GrassAndFungi_filtered.fastq.gz \
    -2 $BASE/filtered_seqs_grass-fungi/${PREFIX}_R2_GrassAndFungi_filtered.fastq.gz
