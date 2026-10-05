#!/bin/bash

BASE=/Users/apple/SyncFolder/CA_curto/mg
WD=$BASE/blast_out_e50
reffasta=$BASE/total_coregenes.fna
OUTDIR=$BASE/parse_results
REFGENDB=/Users/apple/SyncFolder/CA_curto/curto_core_genesDB/masterMD4DB.txt

initial_start=$(date +%s)


now=$(date)
echo ""
echo "Job started at: $now"
echo "################################################################################################"
echo ""


rm -rf $OUTDIR
mkdir $OUTDIR

cd $WD

echo "genomeID" > $OUTDIR/1stcol.txt
cut -f5 $REFGENDB | sort >> $OUTDIR/1stcol.txt

for file in *.blast.txt; do

  sampleID=$(basename $file .blast.txt)
  echo "Processing sample $sampleID"
  outfile=$OUTDIR/${sampleID}.count.txt
  col1=$(cut -f2 $file | cut -d "-" -f2 | sort | uniq -c | awk '{print $1}')
  col2=$(cut -f2 $file | cut -d "-" -f2 | sort | uniq -c | awk '{print $2}')
  paste <(echo $col2 | tr " " "\n") <(echo $col1 | tr " " "\n") > found_temp.txt

  comm -23 <(cut -f5 $REFGENDB | sort) <(cut -f2 $file | cut -d "-" -f2 | sort | uniq) \
    | while read line; do echo -e "$line\t0"; done > missing_temp.txt

  echo "$sampleID" > $outfile
  cat found_temp.txt missing_temp.txt | sort | cut -f2 >> $outfile

  rm found_temp.txt
  rm missing_temp.txt

done

cd $OUTDIR
paste 1stcol.txt *.count.txt > count_table.txt

rm 1stcol.txt
rm *.count.txt

end=$(date)
echo "Job finished at: $end"
echo ""
total_end=$(date +%s)
total_runtime=$(echo "$total_end - $initial_start" | bc -l)
echo "################################################################################################"
echo ""
echo "Total time: $total_runtime seconds"
