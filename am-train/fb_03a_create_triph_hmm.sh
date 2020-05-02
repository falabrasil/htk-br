#!/bin/bash
#
# A script that creates triphones HMMs
#
# Copyright Grupo FalaBrasil (2018)
# Federal University of Pará (UFPA)
#
# Author: April 2018
# Cassio Batista - cassio.batista.13@gmail.com
#
# Reference:
# HTKBook (http://htk.eng.cam.ac.uk/docs/docs.shtml)
# Chapter 3:   A Tutorial Example of Using HTK 
# Section 3.3: Creating Tied-State Triphones

if [[ $DEGUB == true ]] ; then
	echo -e "\e[1mGrupo FalaBrasil - Universidade Federal do Pará\e[0m"
	echo "A script that creates triphones HMMs"
	echo
fi

if [ -z $HTK_PROJECT_DIR ] ; then
	echo "'fb_config.sh' must be sourced beforehand."
	exit 1
elif [ ! -d $HTK_PROJECT_DIR ] ; then
	echo "Error: '$HTK_PROJECT_DIR' must be a dir"
	exit 1
fi

# 3.3 Creating Tied-State Triphones

# crossword triphones
# Context-dependent triphones can be made by simply cloning monophones and then
# re-estimating using triphone transcriptions. The latter should be created
# first using HLEd because a side-effect is to generate a list of all the
# triphones for which there is at least one example in the training data.  
# The following command will convert the monophone transcriptions in
# 'aligned.mlf' to an equivalent set of triphone transcriptions in 'wintri.mlf'. 
# At the same time, a list of triphones is written to the file etc/triphones1.
echo "[HLEd] Making triphones from monophones..."
HLEd \
	-n ${HTK_PROJECT_DIR}/etc/triphones1 \
	-l '*' \
	-i ${HTK_PROJECT_DIR}/etc/wintri.mlf\
	${HTK_PROJECT_DIR}/util/mktri.led\
	${HTK_PROJECT_DIR}/etc/aligned.mlf
	#${HTK_PROJECT_DIR}/etc/phones_sp.mlf

# Substitui o arquivo "trifone" gerado pelo HLEd que possui uma lista incompleta
# de trifones pelo arquivo abaixo que possui todos os possíveis trifones (não
# utiliza monofones nem bifones, com exceção do sil e sp)
# XXX: HTKBook refers to 'word internal triphones'. for some reason the previous
# scripts replace this notation by using only 'word cross triphones''.
cp ${HTK_PROJECT_DIR}/util/allnfone ${HTK_PROJECT_DIR}/etc/triphones1 # FIXME

# Construindo os trifones e fazendo com que todos os trifones com mesmo estado
# central compartilham a mesma matriz de transição
rm   -rf ${HTK_PROJECT_DIR}/model/cd_untied_0
mkdir -p ${HTK_PROJECT_DIR}/model/cd_untied_0

# FIXME I guess this isn't actually happening since some files were overwritten
# This style of triphone transcription is referred to as word internal. Note
# that some biphones will also be generated as contexts at word boundaries will
# sometimes only include two phones. The cloning of models can be done
# efficiently using the HMM editor HHEd:
# XXX: hmm10 -> model/cd_untied_0
echo "[HHEd] Cloninig triphones..."
HHEd \
	-B \
	-H ${HTK_PROJECT_DIR}/model/mono_realign/macros \
	-H ${HTK_PROJECT_DIR}/model/mono_realign/hmmdefs \
	-M ${HTK_PROJECT_DIR}/model/cd_untied_0\
	${HTK_PROJECT_DIR}/etc/mktri.hed \
	${HTK_PROJECT_DIR}/etc/hmm_sp.list
	#-H ${HTK_PROJECT_DIR}/model/mono_sp/macros \
	#-H ${HTK_PROJECT_DIR}/model/mono_sp/hmmdefs \

# Once the context-dependent models have been cloned, the new triphone set can
# be re-estimated using HERest. This is done as previously except that the
# monophone model list is replaced by a triphone list and the triphone
# transcriptions are used in place of the monophone transcriptions. 
# NOTE: For the final pass of HERest, the -s option should be used to generate a
# file of state occupation statistics called stats. In combination with the
# means and variances, these enable likelihoods to be calculated for clusters of
# states and are needed during the state-clustering process described below.
# Re-estimation should be again done twice (4x), so that the resultant model
# sets will ultimately be saved in hmm12.
# XXX: hmm12 -> model/cd_untied_5 -> model/cd_untied
echo -n "[HERest] re-estimation (untied triphones)... "
PRUNING="250.0 150.0 1000"
for i in $(seq 5)
do
	echo -n "$i, "
	mkdir -p ${HTK_PROJECT_DIR}/model/cd_untied_${i}
	HERest \
		-B \
		-I ${HTK_PROJECT_DIR}/etc/wintri.mlf \
		-t $PRUNING \
		-S ${HTK_PROJECT_DIR}/etc/mfc_train.scp \
		-H ${HTK_PROJECT_DIR}/model/cd_untied_$((i-1))/macros \
		-H ${HTK_PROJECT_DIR}/model/cd_untied_$((i-1))/hmmdefs \
		-M ${HTK_PROJECT_DIR}/model/cd_untied_${i} \
		-s ${HTK_PROJECT_DIR}/model/cd_untied_${i}/stats \
		${HTK_PROJECT_DIR}/etc/triphones1 > ${HTK_PROJECT_DIR}/model/cd_untied_${i}/fb_herest.log
done
echo
rm -rf ${HTK_PROJECT_DIR}/model/cd_untied
mv ${HTK_PROJECT_DIR}/model/cd_untied_${i} ${HTK_PROJECT_DIR}/model/cd_untied

#  3.3.2 Step 10 - Making Tied-State Triphones
rm -rf   ${HTK_PROJECT_DIR}/model/cd_tied_0
mkdir -p ${HTK_PROJECT_DIR}/model/cd_tied_0

# The set of triphones used so far only includes those needed to cover the
# training data. The AU command takes as its argument a new list of triphones
# expanded to include all those needed for recognition. This list can be
# generated, for example, by using HDMan on the entire dictionary (not just the
# training dictionary), converting it to triphones using the command TC and
# outputting a list of the distinct triphones to a file using the option -n

echo "[HDMan] Creating triphone dict..."
HDMan \
	-b sp \
	-n ${HTK_PROJECT_DIR}/etc/fulllist \
	-g ${HTK_PROJECT_DIR}/util/global.ded \
	-l ${HTK_PROJECT_DIR}/model/cd_tied_0/fb_hdman.log \
	${HTK_PROJECT_DIR}/etc/dictionary_tri.dic \
	${HTK_PROJECT_DIR}/etc/dictionary.dic

# Decision tree state tying is performed by running HHEd in the normal way
# Notice that the output is saved in a log file. This is important since some
# tuning of thresholds is usually needed.
# XXX: hmm13 -> model/cd_tied_0
echo "[HHEd] Creating tied-state triphones HMMs..."
HHEd \
	-B \
	-H ${HTK_PROJECT_DIR}/model/cd_untied/macros \
	-H ${HTK_PROJECT_DIR}/model/cd_untied/hmmdefs \
	-M ${HTK_PROJECT_DIR}/model/cd_tied_0 \
	${HTK_PROJECT_DIR}/util/bestTree.hed \
	${HTK_PROJECT_DIR}/etc/triphones1 > ${HTK_PROJECT_DIR}/model/cd_tied_0/fb_hhed.log

#cp ./etc/tiedlist ${HTK_PROJECT_DIR}/etc/tiedlist
# Finally, and for the last time, the models are re-estimated twice (4x) using
# HERest. The trained models are then contained in the file 'hmm15/hmmdefs'
# XXX: hmm15/hmmdefs -> model/cd_tied_4/hmmdefs -> model/cd_tied/hmmdefs
echo -n "[HERest] re-estimation (tied triphones)... "
for i in $(seq 4)
do
	echo -n "$i, "
	mkdir -p ${HTK_PROJECT_DIR}/model/cd_tied_${i}
	HERest \
		-B \
		-I ${HTK_PROJECT_DIR}/etc/wintri.mlf \
		-t $PRUNING \
		-S ${HTK_PROJECT_DIR}/etc/mfc_train.scp \
		-H ${HTK_PROJECT_DIR}/model/cd_tied_$((i-1))/macros \
		-H ${HTK_PROJECT_DIR}/model/cd_tied_$((i-1))/hmmdefs \
		-M ${HTK_PROJECT_DIR}/model/cd_tied_${i} \
		${HTK_PROJECT_DIR}/etc/tiedlist > ${HTK_PROJECT_DIR}/model/cd_tied_${i}/fb_herest.log
done
echo
rm -rf ${HTK_PROJECT_DIR}/model/cd_tied
mv ${HTK_PROJECT_DIR}/model/cd_tied_${i} ${HTK_PROJECT_DIR}/model/cd_tied

(play -q doc/KDE-Im-Sms.ogg)&
echo "[FB] End of training step !!!"
echo -e "\e[1mDone!\e[0m"
### EOF ###
