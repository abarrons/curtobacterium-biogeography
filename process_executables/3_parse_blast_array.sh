#!/bin/bash

#SBATCH --job-name=parse_blast           ## Name of the job.
#SBATCH -A JMARTINY_LAB                 ## Account to charge; personal or lab
#SBATCH -p standard                 ## Partition/queue name
#SBATCH --nodes=1                   ## (-N) number of nodes the job will use
#SBATCH --time=10:00:00
#SBATCH --mem-per-cpu=4GB
#SBATCH --cpus-per-task=1           ## number of CPUs to be used per task
#SBATCH -o %x.%A.%a.out             ## File to which STDOUT will be written, %j inserts jobid
#SBATCH -e %x.%A.%a.err             ## File to which STDERR will be written, %j inserts jobid
#SBATCH --array=1-31                ## This value (1-184) depends on the number of samples (.sam files)

BASE=/dfs5/bio/abarrons/CA_curto/mg
WD=$BASE/blast_out_e50_new
OUTDIR=$BASE/parse_results_new
REFGENDB=/dfs5/bio/abarrons/CA_curto/curto_core_genesDB/masterMD4DB.txt

initial_start=$(date +%s)

now=$(date)
echo ""
echo "Job started at: $now"
echo "################################################################################################"
echo ""

# Check if this is the first task
if [[ "$SLURM_ARRAY_TASK_ID" -eq 1 ]]; then

  # make a clean up of the folder and create output directories
  rm -rf $OUTDIR
  mkdir $OUTDIR

  echo "genomeID" > $OUTDIR/1stcol.txt
  cut -f5 $REFGENDB | sort >> $OUTDIR/1stcol.txt

fi

# Check if task ID is 2 or larger and introduce a delay
if [[ "$SLURM_ARRAY_TASK_ID" -ge 2 ]]; then
  sleep 20
fi

cd $WD

file=`ls *.blast.txt | head -n $SLURM_ARRAY_TASK_ID | tail -n 1`


sampleID=$(basename $file .blast.txt)
echo "Processing sample $sampleID"
outfile=$OUTDIR/${sampleID}.count.txt
col1=$(cut -f2 $file | cut -d "-" -f2 | sort | uniq -c | awk '{print $1}')
col2=$(cut -f2 $file | cut -d "-" -f2 | sort | uniq -c | awk '{print $2}')
paste <(echo $col2 | tr " " "\n") <(echo $col1 | tr " " "\n") > ${sampleID}.found_temp.txt

comm -23 <(cut -f5 $REFGENDB | sort) <(cut -f2 $file | cut -d "-" -f2 | sort | uniq) \
  | while read line; do echo -e "$line\t0"; done > ${sampleID}.missing_temp.txt

# Debug: Check missing genome IDs
echo "Missing Genome IDs for $sampleID:"
cat ${sampleID}.missing_temp.txt

echo "$sampleID" > $outfile
cat ${sampleID}.found_temp.txt ${sampleID}.missing_temp.txt | sort -k1,1 > ${sampleID}.combined_temp.txt

# Debug: Check combined and sorted genome IDs and counts
echo "Combined and Sorted Genome IDs and Counts for $sampleID:"
cat ${sampleID}.combined_temp.txt

# Extract counts while preserving alignment with genome IDs
awk '{print $2}' ${sampleID}.combined_temp.txt >> $outfile

rm ${sampleID}.found_temp.txt
rm ${sampleID}.missing_temp.txt
rm ${sampleID}.combined_temp.txt

if [[ "$SLURM_ARRAY_TASK_ID" -lt $SLURM_ARRAY_TASK_MAX ]]; then
  now=$(date)
  echo "Job finished at: $now"
  echo ""
  total_end=$(date +%s)
  total_runtime=$(echo "$total_end - $initial_start" | bc -l)
  echo "################################################################################################"
  echo ""
  echo "Total time: $total_runtime seconds"

fi

# Check if this is the last task
if [[ "$SLURM_ARRAY_TASK_ID" -eq $SLURM_ARRAY_TASK_MAX ]]; then

  echo "Entering loop..."
  # Wait until all other tasks of this job array have finished
    while true; do
        # Count tasks with the same job array ID that are pending or running
        TASK_COUNT=$(squeue -h --name=parse_blast -o "%A" | wc -l)
        echo "Current task count: $TASK_COUNT"

        # If count is 1 (just the last task), break out of the loop
        if [[ $TASK_COUNT -le 1 ]]; then
          echo "Task count is less than or equal to 1, breaking..."
          break
        fi
        echo "Sleeping..."
        # Sleep for a while before checking again
        sleep 15
    done

  echo "Exited loop..."
  sleep 10

   # move to parsed results fodler
   cd $OUTDIR
   paste 1stcol.txt *.count.txt > count_table.txt

   rm 1stcol.txt
   rm *.count.txt


   # print end of process messages
   now=$(date)
   echo "Job finished at: $now"
   echo ""
   total_end=$(date +%s)
   total_runtime=$(echo "$total_end - $initial_start" | bc -l)
   echo "################################################################################################"
   echo ""
   echo "Total time: $total_runtime seconds"

fi
