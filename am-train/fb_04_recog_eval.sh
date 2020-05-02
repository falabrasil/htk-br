#!/bin/bash
#
# A script that evaluates the recogniser
#
# Copyright 2008-2018 Grupo FalaBrasil
#
# Author: April 2018
# Cassio Batista - cassio.batista.13@gmail.com
# Federal University of Pará (UFPA)
#
# References:
# HTKBook (http://htk.eng.cam.ac.uk/docs/docs.shtml)
# Chapter 3: A Tutorial Example of Using HTK 
# Section 3.4: Recogniser Evaluation

if [[ $DEGUB == true ]] ; then
	echo -e "\e[1mGrupo FalaBrasil - Universidade Federal do Pará\e[0m"
	echo "A script that evaluates the recogniser by WER and SER"
	echo
fi

if [ -z $HTK_PROJECT_DIR ] ; then
	echo "'fb_config.sh' must be sourced beforehand."
	exit 1
elif [ ! -d $HTK_PROJECT_DIR ] ; then
	echo "Error: '$HTK_PROJECT_DIR' must be a dir"
	exit 1
fi

# 3.4.1 Step 11 - Recognising the Test Data
# DANGER
# The decoder distributed with HTK, HVite, is only suitable for small and medium
# vocabulary systems and systems using bigrams. For larger vocabulary systems,
# or those requiring trigram language models to be used directly in the search,
# HDecode is available as an extension8 to HTK.  HDecode has been specifically
# written for large vocabulary speech recognition using cross-word triphone
# models. HVite becomes progressively less efficient as the vocabulary size is
# increased and cross-word triphones are used.

find ${HTK_PROJECT_DIR}/wav/test -name "*.mfc" > ${HTK_PROJECT_DIR}/etc/mfc_test.scp

#echo "[HVite] evaluating the model..."
#HVite \
#	-T 1 \
#	-H ${HTK_PROJECT_DIR}/model/cd_tied_16g/macros \
#	-H ${HTK_PROJECT_DIR}/model/cd_tied_16g/hmmdefs \
#	-S ${HTK_PROJECT_DIR}/etc/mfc_test.scp \
#	-i ${HTK_PROJECT_DIR}/etc/recout.mlf \
#	-w $LM_FILE \
#	${HTK_PROJECT_DIR}/etc/dictionary.dic \
#	${HTK_PROJECT_DIR}/etc/tiedlist
#	# -l '*' \
#	#-p 0.0 \
#	#-s 5.0 \

echo "[HDecode] evaluating the model..."
HDecode \
	-T 1 \
	-C ${HTK_PROJECT_DIR}/conf/hvite.conf \
	-t 250.0 150.0 \
	-i ${HTK_PROJECT_DIR}/etc/recout.mlf \
	-H ${HTK_PROJECT_DIR}/model/cd_tied_16g/macros \
	-H ${HTK_PROJECT_DIR}/model/cd_tied_16g/hmmdefs \
	-S ${HTK_PROJECT_DIR}/etc/mfc_test.scp \
	-w $LM_FILE \
	${HTK_PROJECT_DIR}/etc/dictionary.dic \
	${HTK_PROJECT_DIR}/etc/tiedlist > ${HTK_PROJECT_DIR}/fb_hdecode.log
	#${HTK_PROJECT_DIR}/etc/dictionary.dic \
	#-w /home/cassio/bases/LegislacaoBR/constituicao16k/etc/lapsam.lm \

echo "[HLEd] Creating transcription files (testref.mlf)..."
echo "#!MLF!#" > testref.mlf
for txt in $(find ${HTK_PROJECT_DIR}/wav/test -name "*.txt") ; do
	filename=$(basename $txt | sed 's/.txt//g')
	echo "\"*/$filename.lab\"" >> testref.mlf
	for word in $(cat $txt) ; do
		echo $word >> testref.mlf
	done
	echo "." >> testref.mlf
done

mv testref.mlf ${HTK_PROJECT_DIR}/etc

echo "[HResults] evaluating the model..."
HResults \
	-I ${HTK_PROJECT_DIR}/etc/testref.mlf \
	${HTK_PROJECT_DIR}/etc/tiedlist \
	${HTK_PROJECT_DIR}/etc/recout.mlf

(play -q doc/KDE-Im-Sms.ogg)&
echo -e "\e[1mDone!\e[0m"
### EOF ###
