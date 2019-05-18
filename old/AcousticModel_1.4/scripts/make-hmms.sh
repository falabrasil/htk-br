#!/bin/bash
for i in `more hmmlist.txt` ;
do
  echo Training $i	
  HRest -i 30 -T 1 -I labels.mlf -l $i -S mfc_train.list hmms0/$i.hmm
  mv $i hmms0/	
  echo 
  echo	
done
