#!/bin/bash
#
# A script that increases the number of gaussians
#
# Copyright Grupo FalaBrasil (2018)
# Federal University of Pará (UFPA)
#
# Author: April 2018
# Cassio Batista - cassio.batista.13@gmail.com
#
# Reference:
# HTKBook (http://htk.eng.cam.ac.uk/docs/docs.shtml)
# Chapter 10:   HMM System Refinement
# Section 10.6: Mixture Incrementing

if [[ $DEGUB == true ]] ; then
	echo -e "\e[1mGrupo FalaBrasil - Universidade Federal do Pará\e[0m"
	echo "A script that increases the number of gaussians"
	echo
fi

if [ -z $HTK_PROJECT_DIR ] ; then
	echo "'fb_config.sh' must be sourced beforehand."
	exit 1
elif [ ! -d $HTK_PROJECT_DIR ] ; then
	echo "Error: '$HTK_PROJECT_DIR' must be a dir"
	exit 1
fi

PRUNING="250.0 150.0 1000"
ln -s ${HTK_PROJECT_DIR}/model/cd_tied ${HTK_PROJECT_DIR}/model/cd_tied_1g # make things easier for the loop -- CB
for (( g=2; g<=$MAX_GAUSS; g*=2 )) ; do
	echo "[HHEd] increasing gaussian mixture from $((g/2)) to $g ...."
	mkdir -p  ${HTK_PROJECT_DIR}/model/cd_tied_${g}g_0
	HHEd \
		-H ${HTK_PROJECT_DIR}/model/cd_tied_$((g/2))g/macros \
		-H ${HTK_PROJECT_DIR}/model/cd_tied_$((g/2))g/hmmdefs \
		-M ${HTK_PROJECT_DIR}/model/cd_tied_${g}g_0 \
		${HTK_PROJECT_DIR}/util/mix${g}.hed \
		${HTK_PROJECT_DIR}/etc/tiedlist

	echo -n  "[HERest] $g Gaussians / mix "
	for i in $(seq 2)
	do
	echo -n "$i, "
	mkdir -p  ${HTK_PROJECT_DIR}/model/cd_tied_${g}g_${i}
	HERest \
		-B \
		-u tmvw \
		-t $PRUNING \
		-I ${HTK_PROJECT_DIR}/etc/wintri.mlf \
		-S ${HTK_PROJECT_DIR}/etc/mfc_train.scp \
		-H ${HTK_PROJECT_DIR}/model/cd_tied_${g}g_$((i-1))/macros \
		-H ${HTK_PROJECT_DIR}/model/cd_tied_${g}g_$((i-1))/hmmdefs \
		-M ${HTK_PROJECT_DIR}/model/cd_tied_${g}g_${i} \
		${HTK_PROJECT_DIR}/etc/tiedlist > ${HTK_PROJECT_DIR}/model/cd_tied_${g}g_${i}/fb_herest.log
	done
	echo
	rm -rf ${HTK_PROJECT_DIR}/model/cd_tied_${g}g
	mv     ${HTK_PROJECT_DIR}/model/cd_tied_${g}g_${i} ${HTK_PROJECT_DIR}/model/cd_tied_${g}g
done
rm ${HTK_PROJECT_DIR}/model/cd_tied_1g # since we don't neet this symlink anymore -- CB

(play -q doc/KDE-Im-Sms.ogg)&
echo -e "\e[1mDone!\e[0m"
### EOF ###
