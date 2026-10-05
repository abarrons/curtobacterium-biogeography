#!/bin/bash

#SBATCH --job-name=fastq_counts  ## Name of the job.
#SBATCH -A JMARTINY_LAB                ## Account to charge; personal or lab
#SBATCH -p standard                    ## Partition/queue name
#SBATCH --time=2:00:00
#SBATCH --nodes=1                      ## (-N) number of nodes the job will use
#SBATCH --mem=4GB                     ## number of OpenMP threads - total RAM request = 4 * 4.5GB/core = 18G
#SBATCH --cpus-per-task=1              ## number of CPUs to be used per task
#SBATCH -o %x.%A.%a.out             ## File to which STDOUT will be written, %j inserts jobid
#SBATCH -e %x.%A.%a.err             ## File to which STDERR will be written, %j inserts jobid


# Set folder paths
BASE=/dfs5/bio/abarrons/CA_curto/mg
WD=$BASE/raw_seqs


for file in *1.fq; do
 sample=$(echo $file | cut -d "." -f1 | tr -d "-")
 count=$(grep -c "@" $file); echo -e "$sample\t$count"
done > fastq_counts.txt
