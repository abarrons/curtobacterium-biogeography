#!/bin/bash

BASE=/dfs5/bio/abarrons/CA_curto/mg
WD=$BASE/raw_seqs
BU=$BASE/raw_seqs_bu

rm -rf $WD
mkdir $WD
cd $BU

nfiles=$(ls $BU/*.gz | wc -l)

count=1
for file in *.gz; do
    # Construct the new filename

    echo "copying file $count of $nfiles"
    echo "copying: $file"

    cp "$file" "$WD/$file"

    count=`expr $count + 1`
done
