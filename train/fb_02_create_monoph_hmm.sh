#!/bin/bash
#
# This script creates monophones HMMs
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
# Section 3.2: Creating Monophone HMMs

if [[ $DEGUB == true ]] ; then
	echo -e "\e[1mGrupo FalaBrasil - Universidade Federal do Pará\e[0m"
	echo "A script that creates monophone HMMs"
	echo
fi

if [ -z $HTK_PROJECT_DIR ] ; then
	echo "'fb_config.sh' must be sourced beforehand."
	exit 1
elif [ ! -d $HTK_PROJECT_DIR ] ; then
	echo "Error: '$HTK_PROJECT_DIR' must be a dir"
	exit 1
fi

# 3.2.1 Step 6 - Creating Flat Start Monophones
# The first step in HMM training is to define a prototype model. The parameters
# of this model are not important, its purpose is to define the model topology.
# For phone-based systems, a good topology to use is 3-state left-right with no
# skips such as the following
echo "[FB] Init HMM prototype..."
mkdir -p ${HTK_PROJECT_DIR}/model/flat_start
#cp ${HTK_PROJECT_DIR}/util/proto ${HTK_PROJECT_DIR}/model/flat_start 

# The HTK tool HCompV will scan a set of data files, compute the global mean and
# variance and set all of the Gaussians in a given HMM to have the same mean and
# variance. The following command will create a new version of proto in the
# directory hmm0 (-M model/flat_start) in which the zero means and unit
# variances above have been replaced by the global speech means and variances.
echo "[HCompV] Computing global mean and variances for gaussians..."
find ${HTK_PROJECT_DIR}/wav/train -name "*.mfc" > ${HTK_PROJECT_DIR}/etc/mfc_train.scp
HCompV\
	-C ${HTK_PROJECT_DIR}/conf/hcomp.conf\
	-f 0.01\
	-m\
	-S ${HTK_PROJECT_DIR}/etc/mfc_train.scp\
	-M ${HTK_PROJECT_DIR}/model/flat_start\
	${HTK_PROJECT_DIR}/util/proto 

# Create a 'proto' model for each phoneme
echo -n "[FB] Creating HMMs for each phoneme... "
for phone in $(cat ${HTK_PROJECT_DIR}/etc/hmm.list) ; do
	cat ${HTK_PROJECT_DIR}/model/flat_start/proto | sed 's/proto/'$phone'/g' > ${HTK_PROJECT_DIR}/model/flat_start/${phone}
	echo -ne "\r\t\t\t\t\t\t\t\t$phone"
done
echo

# Given this new prototype model stored in the directory hmm0 (model/flat_start), 
# a MMF file called 'hmmdefs' containing a copy for each of the required
# monophone HMMs is constructed by """manually""" copying the prototype and
# relabelling it for each required monophone (including "sil") 
# TODO troquei hmms.mlf por hmms.mmf
echo "[HHEd] Creating macros and hmmdefs"
HHEd\
	-w ${HTK_PROJECT_DIR}/model/flat_start/hmms.mmf\
	-d ${HTK_PROJECT_DIR}/model/flat_start\
	${HTK_PROJECT_DIR}/util/concatenade.hed\
	${HTK_PROJECT_DIR}/etc/hmm.list

head -n  3 ${HTK_PROJECT_DIR}/model/flat_start/hmms.mmf >  ${HTK_PROJECT_DIR}/model/flat_start/macros
tail -n +4 ${HTK_PROJECT_DIR}/model/flat_start/hmms.mmf >  ${HTK_PROJECT_DIR}/model/flat_start/hmmdefs

# The flat start monophones stored in the directory hmm0 are re-estimated using
# the embedded re-estimation tool HERest invoked as follows.
# The effect of this is to load all the models in hmm0 (model/flat_start) which
# are listed in the model list monophones0 (hmm.list, which is monophones1
# (hmm_sp.list) less the short pause (sp) model). These are then re-estimated
# them using the data listed in train.scp (mfc_train.scp) and the new
# model set is stored in the directory hmm1 
# XXX: hmm1 -> model/mono_0
PRUNING="250.0 150.0 1000"
echo "[HERest] 0th re-estimation (flat start)... "
mkdir -p ${HTK_PROJECT_DIR}/model/mono_0
HERest\
	-I ${HTK_PROJECT_DIR}/etc/phones0.mlf\
	-t $PRUNING\
	-S ${HTK_PROJECT_DIR}/etc/mfc_train.scp\
	-H ${HTK_PROJECT_DIR}/model/flat_start/macros\
	-H ${HTK_PROJECT_DIR}/model/flat_start/hmmdefs\
	-M ${HTK_PROJECT_DIR}/model/mono_0\
	${HTK_PROJECT_DIR}/etc/hmm.list > ${HTK_PROJECT_DIR}/model/mono_0/fb_herest.log

# Each time HERest is run it performs a single re-estimation. Each new HMM set
# is stored in a new directory. Execution of HERest should be repeated twice
# (9x) more, changing the name of the input and output directories (set with the
# options -H and -M) each time, until the directory 
# 'hmm3' (model/mono_9 -> model/mono after 'mv') contains the final set of
# initialised monophone HMMs.
echo -n "[HERest] re-estimation... "
for i in $(seq 9) ; do
	echo -n "$i, "
	mkdir -p ${HTK_PROJECT_DIR}/model/mono_${i}
	HERest\
		-I ${HTK_PROJECT_DIR}/etc/phones0.mlf\
		-t $PRUNING\
		-S ${HTK_PROJECT_DIR}/etc/mfc_train.scp\
		-H ${HTK_PROJECT_DIR}/model/mono_$((i-1))/macros\
		-H ${HTK_PROJECT_DIR}/model/mono_$((i-1))/hmmdefs\
		-M ${HTK_PROJECT_DIR}/model/mono_${i}\
		${HTK_PROJECT_DIR}/etc/hmm.list > ${HTK_PROJECT_DIR}/model/mono_${i}/fb_herest.log
done
echo
rm -rf ${HTK_PROJECT_DIR}/model/mono
mv ${HTK_PROJECT_DIR}/model/mono_${i} ${HTK_PROJECT_DIR}/model/mono

# 3.2.2 Step 7 - Fixing the Silence Models
# Use a text editor on the file hmm3/hmmdefs to copy the centre state of the
# sil model to make a new sp model and store the resulting MMF hmmdefs, which
# includes the new sp model, in the new directory hmm4.
# TODO https://askubuntu.com/questions/849014/grep-show-lines-until-certain-pattern
echo "[FB] Adding short pause (sp)..."
mkdir -p ${HTK_PROJECT_DIR}/model/mono_sp_0
echo \
"~h \"sp\"
<BEGINHMM>
<NUMSTATES> 3
<STATE> 2
$(cat ${HTK_PROJECT_DIR}/model/mono/hmmdefs |\
		grep -A27 '^~h "sil"' | grep -A5 '<STATE> 3' | tail -n +2)
<TRANSP> 3
 0.0 1.0 0.0
 0.0 0.5 0.5
 0.0 0.0 1.0
<ENDHMM>" > ${HTK_PROJECT_DIR}/model/mono_sp_0/sp

# Run the HMM editor HHEd to add the extra transitions required and tie the sp
# state to the centre sil state
# The parameters of this tied-state are stored in the hmmdefs file and within
# each silence model, the original state parameters are replaced by the name of
# this macro. Note that the phone list used here has been changed, because the
# original list monophones0 (hmm.list) has been extended by the new sp model.
# The new file is called monophones1 (hmm_sp.list) and has been (will be) used
# in the above (below) HHEd command.
echo "[HHEd] Adding extra transitions, tie sp to sil..."
cp ${HTK_PROJECT_DIR}/model/mono/macros ${HTK_PROJECT_DIR}/model/mono_sp_0
cat ${HTK_PROJECT_DIR}/model/mono/hmmdefs ${HTK_PROJECT_DIR}/model/mono_sp_0/sp > ${HTK_PROJECT_DIR}/model/mono_sp_0/hmmdefs

mkdir -p ${HTK_PROJECT_DIR}/model/mono_sp_1
HHEd\
	-H ${HTK_PROJECT_DIR}/model/mono_sp_0/macros\
	-H ${HTK_PROJECT_DIR}/model/mono_sp_0/hmmdefs\
	-M ${HTK_PROJECT_DIR}/model/mono_sp_1\
	${HTK_PROJECT_DIR}/util/sil.hed\
	${HTK_PROJECT_DIR}/etc/hmm_sp.list

# Finally, another two (8x) passes of HERest are applied using the phone
# transcriptions with sp models between words. This leaves the set of monophone
# HMMs created so far in the directory hmm7 
# XXX: hmmm]7 -> model/mono_sp_10 -> model/mono_sp
echo -n "[HERest] re-estimation (sp)... "
for i in $(seq 2 10) ; do
	# WARNING [-2331]  UpdateModels: sp[36] copied: only 0 egs in HERest
	echo -n "$((i-1)) ($((i+3))), "
	mkdir -p ${HTK_PROJECT_DIR}/model/mono_sp_${i}
	HERest\
		-I ${HTK_PROJECT_DIR}/etc/phones_sp.mlf\
		-t $PRUNING\
		-S ${HTK_PROJECT_DIR}/etc/mfc_train.scp\
		-H ${HTK_PROJECT_DIR}/model/mono_sp_$((i-1))/macros\
		-H ${HTK_PROJECT_DIR}/model/mono_sp_$((i-1))/hmmdefs\
		-M ${HTK_PROJECT_DIR}/model/mono_sp_${i}\
		${HTK_PROJECT_DIR}/etc/hmm_sp.list > ${HTK_PROJECT_DIR}/model/mono_sp_${i}/fb_herest.log
done
echo
rm -rf ${HTK_PROJECT_DIR}/model/mono_sp
mv ${HTK_PROJECT_DIR}/model/mono_sp_${i} ${HTK_PROJECT_DIR}/model/mono_sp

# 3.2.3 Step 8 - Realigning the Training Data
# The phone models created so far can be used to realign the training data and
# create new transcriptions. This can be done with a single invocation of the
# HTK recognition tool HVite, viz.
# This command uses the HMMs stored in hmm7 (model/mono_sp) to transform the
# input word level transcription words.mlf to the new phone level transcription
# aligned.mlf using the pronunciations stored in the dictionary dict.
# The name silence is used on the assumption that the dictionary contains an
# entry "sil sil" (FIXME is that it?)
echo "[HVite] Realigning training data..."
mkdir -p ${HTK_PROJECT_DIR}/model/mono_realign_0
cp ${HTK_PROJECT_DIR}/model/mono_sp/{macros,hmmdefs} ${HTK_PROJECT_DIR}/model/mono_realign_0
HVite\
	-o SWT\
	-b sil\
	-a\
	-y lab\
	-m\
	-t 250.0\
	-I ${HTK_PROJECT_DIR}/etc/words.mlf\
	-i ${HTK_PROJECT_DIR}/etc/aligned.mlf\
	-H ${HTK_PROJECT_DIR}/model/mono_realign_0/macros\
	-H ${HTK_PROJECT_DIR}/model/mono_realign_0/hmmdefs\
	-S ${HTK_PROJECT_DIR}/etc/mfc_train.scp\
	${HTK_PROJECT_DIR}/etc/dictionary.dic\
	${HTK_PROJECT_DIR}/etc/hmm_sp.list
	#-l '*' # there's a MLF, no need to make HVite look for individual .lab files

# Once the new phone alignments have been created, another 2 passes of HERest
# can be applied to reestimate the HMM set parameters again. Assuming that this
# is done, the final monophone HMM set will be stored in directory hmm9
# XXX: hmm9 -> model/mono_realign_2 -> model/mono_realign
echo -n "[HERest] re-estimation (aligned sp)... "
for i in $(seq 2) ; do
	echo -n "$i ($((i+13))), "
	mkdir -p ${HTK_PROJECT_DIR}/model/mono_realign_${i}
	HERest\
		-I ${HTK_PROJECT_DIR}/etc/aligned.mlf\
		-t $PRUNING\
		-S ${HTK_PROJECT_DIR}/etc/mfc_train.scp\
		-H ${HTK_PROJECT_DIR}/model/mono_realign_$((i-1))/macros\
		-H ${HTK_PROJECT_DIR}/model/mono_realign_$((i-1))/hmmdefs\
		-M ${HTK_PROJECT_DIR}/model/mono_realign_${i}\
		${HTK_PROJECT_DIR}/etc/hmm_sp.list > ${HTK_PROJECT_DIR}/model/mono_realign_${i}/fb_herest.log
done
echo
rm -rf ${HTK_PROJECT_DIR}/model/mono_realign
mv ${HTK_PROJECT_DIR}/model/mono_realign_${i} ${HTK_PROJECT_DIR}/model/mono_realign

(play -q doc/KDE-Im-Sms.ogg)&
echo -e "\e[1mDone!\e[0m"
### EOF ###
