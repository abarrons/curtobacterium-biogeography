#!/bin/bash

#SBATCH --job-name=count_total_unique_hits  ## Name of the job.
#SBATCH -A JMARTINY_LAB                ## Account to charge; personal or lab
#SBATCH -p standard                    ## Partition/queue name
#SBATCH --time=2:00:00
#SBATCH --nodes=1                      ## (-N) number of nodes the job will use
#SBATCH --mem-per-cpu=4GB
#SBATCH --cpus-per-task=1              ## number of CPUs to be used per task
#SBATCH -o %x.%A.%a.out             ## File to which STDOUT will be written, %j inserts jobid
#SBATCH -e %x.%A.%a.err             ## File to which STDERR will be written, %j inserts jobid
#SBATCH --array=1-188                ## This value (1-184) depends on the number of samples (.sam files)


## Set environmental variables

BASE=/dfs5/bio/abarrons/CA_curto/mg
WD=$BASE/blast_out_prok
PROGRAM_PATH=/dfs5/bio/abarrons/programs


cd $WD

# Check if this is the first task
if [[ "$SLURM_ARRAY_TASK_ID" -eq 1 ]]; then

  # make a the output file
  echo -e "sample\tcount" > total_prok_counts.txt

fi

# Check if task ID is 2 or larger and introduce a delay
if [[ "$SLURM_ARRAY_TASK_ID" -ge 2 ]]; then
  sleep 5
fi


## Set environmental variables specific for the job
INFILE=`ls *.blast.txt | head -n $SLURM_ARRAY_TASK_ID | tail -n 1`
## echo file name
echo "$INFILE"
# get sample ID from file name
SAMPLE=$(echo $INFILE | cut -d "." -f1 | tr -d "-");

# echo which sample is being processed
echo "Processing sample: $SAMPLE"
# count how many query sequences had at least one hit in the data base
# and store the value in a variable
count=$(cut -f1 $INFILE | sort | uniq | wc -l)

# direct output to output file
echo -e "$SAMPLE\t$count" >> total_prok_counts.txt
