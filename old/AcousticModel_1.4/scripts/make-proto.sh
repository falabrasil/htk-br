#!/bin/bash
for i in `more hmmlist.txt` ;
do
  cat hmms0/proto.hmm | sed s/proto/$i/g > hmms0/$i ;
  echo "Finished processing $i";
done
