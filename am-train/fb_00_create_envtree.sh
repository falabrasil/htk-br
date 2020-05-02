#!/bin/bash
#
# This script create an environment tree for training acoustic models with HTK 
#
# Copyright Grupo FalaBrasil (2018)
# Federal University of Pará (UFPA)
#
# Author: April 2018
# Cassio Batista - cassio.batista.13@gmail.com
#
# Reference:
# HTKBook (http://htk.eng.cam.ac.uk/docs/docs.shtml)
# Chapter 3: A Tutorial Example of Using HTK 

if [[ $DEGUB == true ]] ; then
	echo -e "\e[1mGrupo FalaBrasil - Universidade Federal do Pará\e[0m"
	echo "A script to create the environment tree for training AMs according to HTK's pattern."
	echo "Reference: http://htk.eng.cam.ac.uk/docs/docs.shtml"
fi

if [ -z $HTK_PROJECT_DIR ] ; then
	echo "'fb_config.sh' must be sourced beforehand."
	exit 1
elif [ -d $HTK_PROJECT_DIR ] ; then
	echo -n "'$HTK_PROJECT_DIR' exists as dir. Override? [y/N] "
	read ans
	if [[ "$ans" != "y" ]] ; then
		echo "aborted."
		exit 0
	else
		rm -rf $HTK_PROJECT_DIR
	fi
fi

mkdir -p $HTK_PROJECT_DIR

echo "[FB] Creating dir 'conf/' for configuration files"
mkdir ${HTK_PROJECT_DIR}/conf

# HCompV config file
echo "TARGETKIND = MFCC_E_D_A_Z" > ${HTK_PROJECT_DIR}/conf/hcomp.conf

# E_D_A_Z.conf
echo \
"USESILDET = FALSE
ENORMALISE = T
NUMCEPS = 12
CEPLIFTER = 22
NUMCHANS = 26
#USEPOWER = FALSE
PREEMCOEF = 0.97
USEHAMMING = T
WINDOWSIZE = 250000.0
SAVEWITHCRC = F 
SAVECOMPRESSED = F 
TARGETRATE = 100000.0
TARGETKIND = MFCC_E_D_A_Z
ZMEANSOURCE = T
SOURCEFORMAT = WAV
#SOURCEKIND  = WAVEFORM
#SOURCERATE  = 625" > ${HTK_PROJECT_DIR}/conf/edaz.conf

# HVite/HDecode config file
echo \
"ALLOWCXTEXP = T 
FORCECXTEXP = T

#CrossWord
ALLOWXWRDEXP = T

#sp como wordboundary
CFWORDBOUNDARY = FALSE" > ${HTK_PROJECT_DIR}/conf/hvite.conf

echo -e "STARTWORD = <s>\nENDWORD = </s>" > ${HTK_PROJECT_DIR}/conf/hlrescore.conf

echo "[FB] Creating dir 'util/' mainly for edition files"
mkdir ${HTK_PROJECT_DIR}/util
cp ./util/* ${HTK_PROJECT_DIR}/util

# XXX We had to edit the header and the footer paths inside the tree file in
# order to update'em to the full path of our HTK project -- CB
echo "RO 100.0 \"${HTK_PROJECT_DIR}/model/cd_untied/stats\"" > ${HTK_PROJECT_DIR}/util/bestTree.hed 
tail -n +2 ./util/bestTree.hed | head -n -1   >> ${HTK_PROJECT_DIR}/util/bestTree.hed
#echo "AU \"${HTK_PROJECT_DIR}/etc/fulllist\""               >> ${HTK_PROJECT_DIR}/util/bestTree.hed # updt footer
echo "CO \"${HTK_PROJECT_DIR}/etc/tiedlist\""               >> ${HTK_PROJECT_DIR}/util/bestTree.hed # updt footer

# mkphones.led
echo -e "EX\nIS sil sil\nDE sp" > ${HTK_PROJECT_DIR}/util/mkphones.led

# mkphones_sp.led
echo -e "EX\nIS sil sil" > ${HTK_PROJECT_DIR}/util/mkphones_sp.led

# mktri.led
# XXX: appending comments from previous scripts (mkCrossWord.led) -- CB
echo -e "WB sp\nNB sp\nTC" > ${HTK_PROJECT_DIR}/util/mktri.led
echo -e "#NB sp\n#TC\n#IT\n#RE sil sil\n#RE sp sp" >> ${HTK_PROJECT_DIR}/util/mktri.led

# global.ded
echo -e "AS sp\n#RS cmu\nMP sil sil sp\nTC" > ${HTK_PROJECT_DIR}/util/global.ded

# HTKBook's section 3.2.1 Step 6: Creating Flat Start Monophones
# hmm proto for flat start
# The first step in HMM training is to define a prototype model. The parameters
# of this model are not important, its purpose is to define the model topology.
# For phone-based systems, a good topology to use is 3-state left-right with no
# skips such as the following 
echo \
"~o
<STREAMINFO> 1 39
<VECSIZE> 39 <NULLD> <MFCC_E_D_A_Z>
~h \"proto\"
<BEGINHMM>
<NUMSTATES> 5
$(for i in $(seq 2 4); do \
echo \
"<STATE> $i
<MEAN> 39
$(for i in $(seq 39); do echo -n "0.0 " ; done)
<VARIANCE> 39
$(for i in $(seq 39); do echo -n "1.0 " ; done)"
done)
<TRANSP> 5
 0.0 1.0 0.0 0.0 0.0
 0.0 0.5 0.5 0.0 0.0
 0.0 0.0 0.5 0.5 0.0
 0.0 0.0 0.0 0.5 0.5
 0.0 0.0 0.0 0.0 1.0
<ENDHMM>" > ${HTK_PROJECT_DIR}/util/proto

# sil.hed
echo \
"AT 2 4 0.2 {sil.transP}
AT 4 2 0.2 {sil.transP}
AT 1 3 0.3 {sp.transP}
TI silst {sil.state[3],sp.state[2]}" > ${HTK_PROJECT_DIR}/util/sil.hed

# NOTE: this file was empty on the previous project -- CB
touch ${HTK_PROJECT_DIR}/util/concatenade.hed

# HTKBook's section 10.6: Mixture Incrementing
# NOTE: if you want to increase to a specific number of gaussians (e.g.: 11),
# you need to edit this loop to, let's say, `for i in $(seq 2 11)`. -- CB
for (( i=2; i<=256; i*=2 )) ; do
	echo "MU $i {*.state[2-999].mix}" >> ${HTK_PROJECT_DIR}/util/mix${i}.hed
done

echo "[FB] Creating dir 'etc/' for data-dependent files..."
mkdir ${HTK_PROJECT_DIR}/etc

phones="a a~ b d dZ e e~ E f g i i~ j j~ J k l L m n o o~ O p r R s S sil t tS u u~ v w w~ X z Z"
for ph in $phones ; do
	echo $ph >> ${HTK_PROJECT_DIR}/etc/hmm.list     # NOTE: monophones0
	echo $ph >> ${HTK_PROJECT_DIR}/etc/hmm_sp.list  # NOTE: monophones1
done
echo "sp" >> ${HTK_PROJECT_DIR}/etc/hmm_sp.list

# step 9
#  the edit script mktri.hed contains a clone command CL followed by TI commands
#  to tie all of the transition matrices in each triphone set
echo "CL \"${HTK_PROJECT_DIR}/etc/triphones1\"" > ${HTK_PROJECT_DIR}/etc/mktri.hed
while read ph ; do
	echo "TI T_${ph} {(*-${ph}+*,${ph}+*,*-${ph}).transP}" >> ${HTK_PROJECT_DIR}/etc/mktri.hed
done < ${HTK_PROJECT_DIR}/etc/hmm_sp.list

echo "[FB] Creating dir 'wav/' for symlinking the data..."
mkdir -p ${HTK_PROJECT_DIR}/wav/{train,test}

(play -q doc/KDE-Im-Sms.ogg)&
echo -e "\e[1mDone!\e[0m"
tree -v $HTK_PROJECT_DIR
echo "check out your project dir at '$(readlink -f $HTK_PROJECT_DIR)'"
### EOF ###
