#!/bin/bash

#SBATCH --job-name=qc_filter_euk          ## Name of the job.
#SBATCH -A JMARTINY_LAB                 ## Account to charge; personal or lab
#SBATCH -p standard                 ## Partition/queue name
#SBATCH --time=24:00:00
#SBATCH --nodes=1                   ## (-N) number of nodes the job will use
#SBATCH --mem-per-cpu=4GB
#SBATCH --cpus-per-task=16          ## number of CPUs to be used per task
#SBATCH -o %x.%A.%a.out             ## File to which STDOUT will be written, %j inserts jobid
#SBATCH -e %x.%A.%a.err             ## File to which STDERR will be written, %j inserts jobid
#SBATCH --array=1-10                ## This value (1-184) depends on the number of samples i.e. 1-num. samples



BASE=/dfs5/bio/abarrons/CA_curto/mg
WD=$BASE/raw_seqs_new
REFGENOMES_PATH=/dfs5/bio/abarrons/ref_genomes
BBMAPDIR=/dfs5/bio/abarrons/programs/bbmap/resources
REFGENP=$REFGENOMES_PATH/GCA_001735685.1_ASM173568v1_genomic.fna
REFGENF=$REFGENOMES_PATH/GCA_008086845.1_ASM808684v1_genomic.fna
OUTDIR=$BASE/filtered_seqs_new
THREADS=16

module load bbmap/38.96
module load bwa/0.7.17
module load picard-tools/1.87
module load samtools/1.15.1


cd $WD


# renaming file names to give them sampleIDS
# we need a mpping fule that matches barcodes to sequnce filename

# Check if this is the first task
if [[ "$SLURM_ARRAY_TASK_ID" -eq 1 ]]; then
  #rm -rf $OUTDIR
  #mkdir $OUTDIR

  rm -f *.clean.*
  rm -f *.sai
  rm -f *.fq
#  # Loop through each line of the mapping file
#  while IFS=$'\t' read -r sampleID barcode1 barcode2; do
#      # Find the corresponding files using the barcodes and rename them
#      for file in nR235-L2-G1-*-${barcode1}-${barcode2}-READ*-Sequences.txt.gz; do
#          # Construct the new filename
#          read_identifier=$(echo $file | grep -o "READ[12]")
#          new_filename="${sampleID}-${read_identifier}-Sequences.txt.gz"
#          mv "$file" "$new_filename"
#        done
#      # here we feed the maping file
#      done < $BASE/seqIDs_bc.txt
#
fi

## Check if task ID is greater than  2 introduce a delay for the rneaming step
if [[ "$SLURM_ARRAY_TASK_ID" -ge 2 ]]; then
  sleep 20
fi


#assign a files and sampleID to a specific taks in the array
#FFILE=$(ls *-READ1-Sequences.txt.gz | head -n $SLURM_ARRAY_TASK_ID | tail -n 1)
FFILE=$(ls *-READ1-Sequences.txt.gz | grep -E "^($(tr '\n' '|' < need_qc_again.txt | sed 's/|$//'))-READ1" | head -n $SLURM_ARRAY_TASK_ID | tail -n 1) # use this when some samples need to be QCed again
# here we capture the samplem ID
REF=`basename $FFILE -READ1-Sequences.txt.gz` ;
RFILE="${REF}-READ2-Sequences.txt.gz"


### quality filtering step
#Run BBduk
bbduk.sh in1=$FFILE in2=$RFILE \
out1=$REF.clean1.fq out2=$REF.clean2.fq \
minlen=25 qtrim=rl trimq=10 -Xmx20g threads=$THREADS ktrim=r k=25 ref=$BBMAPDIR/adapters.fa hdist=1

# bwa index -a is $REFGENP


# Align against reference genome of Grass (Lolium perenne) to remove eukaryotic sequences
# using BWA and then samtools to ransform .sam files to .bam
# and then filter unmaped sequences and return
# only unmaped sequences into fwd (R1) and rev (R2) fastq files
# Job:
# bwa aln maps reads to reference genome
# samtools view transforms .sam file to. bam and filters out maped reads
# samtools fastq will give you the R1 and R2 fastq files

bwa aln $REFGENP $REF.clean1.fq -t $THREADS > $REF.clean1.sai
bwa aln $REFGENP $REF.clean2.fq -t $THREADS > $REF.clean2.sai

bwa samse $REFGENP \
  $REF.clean1.sai $REF.clean1.fq > $REF.bwaP.R1.sam
bwa samse $REFGENP \
  $REF.clean2.sai $REF.clean2.fq > $REF.bwaP.R2.sam
rm $REF.*.sai
#rm $REF.clean1.fq
#rm $REF.clean2.fq

samtools view $REF.bwaP.R1.sam -b -o $REF.bwaP.R1.bam
samtools view $REF.bwaP.R2.sam -b -o $REF.bwaP.R2.bam
rm $REF.*.sam

reformat.sh in=$REF.bwaP.R1.bam out=$REF.bwaP.R1.fq unmappedonly
reformat.sh in=$REF.bwaP.R2.bam out=$REF.bwaP.R2.fq unmappedonly
rm $REF.*.bam

# bwa index -a is $REFGENF


## Align against reference genome of fungus (Pyrenophora teres) to remove eukaryotic sequences
## using BWA and then samtools to ransform .sam files to .bam
## and then filter unmaped sequences and return
## only unmaped sequences into fwd (R1) and rev (R2) fastq files
## Job:
## bwa aln maps reads to reference genome
## samtools view transforms .sam file to. bam and filters out maped reads
## samtools fastq will give you the R1 and R2 fastq files

bwa aln $REFGENF $REF.bwaP.R1.fq -t $THREADS > $REF.bwaP.R1.sai
bwa aln $REFGENF $REF.bwaP.R2.fq -t $THREADS > $REF.bwaP.R2.sai

bwa samse $REFGENF \
  $REF.bwaP.R1.sai $REF.bwaP.R1.fq > $REF.filter.R1.sam
bwa samse $REFGENF \
  $REF.bwaP.R2.sai $REF.bwaP.R2.fq > $REF.filter.R2.sam
rm $REF.*.sai

samtools view $REF.filter.R1.sam -b -o $REF.filter.R1.bam
samtools view $REF.filter.R2.sam -b -o $REF.filter.R2.bam
rm $REF.*.sam

reformat.sh in=$REF.filter.R1.bam out=$REF.filter.R1.fq unmappedonly
reformat.sh in=$REF.filter.R2.bam out=$REF.filter.R2.fq unmappedonly
rm $REF.*.bam


# finally let's get merged sequences and filtered forwrad sequences into a
# single fasta file so we can use the most of the data
repair.sh in=$REF.filter.R1.fq in2=$REF.filter.R2.fq \
  out=$REF.filter.clean.R1.fq.gz out2=$REF.filter.clean.R2.fq.gz

bbmerge.sh \
  in1=$REF.filter.clean.R1.fq.gz in2=$REF.filter.clean.R2.fq.gz \
  out=$REF.filter.clean.merged.fq.gz outu=$REF.filter.clean.unmerged.fq.gz

reformat.sh in=$REF.filter.clean.merged.fq.gz out=$REF.filter.clean.merged.fa
reformat.sh in=$REF.filter.clean.unmerged.fq.gz out=$REF.filter.clean.unmerged.fa

cat $REF.filter.clean.merged.fa $REF.filter.clean.unmerged.fa > $OUTDIR/$REF.filter.total.fa
rm $REF.filter.clean.merged.fq.gz
rm $REF.filter.clean.unmerged.fq.gz
rm $REF.filter.clean.merged.fa
rm $REF.filter.clean.unmerged.fa
