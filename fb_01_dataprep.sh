#!/bin/bash
#
# This script creates symlinks of the audio dataset within the wav/ folder
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
# Section 3.1: Data Preparation 

if [[ $DEGUB == true ]] ; then
	echo -e "\e[1mGrupo FalaBrasil - Universidade Federal do Pará\e[0m"
	echo "A script that creates symlinks of the audio dataset within the wav/ folder"
	echo
fi

if [ -z $HTK_PROJECT_DIR ] ; then
	echo "'fb_config.sh' must be sourced beforehand."
	exit 1
elif [ ! -d $AUDIO_DATA_DIR ] || [ ! -d $HTK_PROJECT_DIR ] ; then
	echo "Error: both '$AUDIO_DATA_DIR' and '$HTK_PROJECT_DIR' must be dirs"
	exit 2
fi

# split train test: data is symlinked on background to speed things up
split_dataset_bg() {
	# define the ID speaker (same name of the folder)
	spkr=$(readlink -f $2 | sed 's/\// /g' | awk '{print $(NF-1)}')

	# get the fullpath of audio and transcriptions files
	wav=$(readlink -f ${2}.wav) 
	txt=$(readlink -f ${2}.txt) 

	# create a dir for the speaker and XXX link both files to it
	mkdir -p    ${1}/${spkr}
	ln -sf $wav ${1}/${spkr}
	ln -sf $txt ${1}/${spkr} 
}

# split train test
split_dataset() {
	argv=($1 $2)
	for ds in ${argv[@]} ; do
		echo -ne "[FB] Defining $ds set: "
		basedir="${HTK_PROJECT_DIR}/wav/${ds}"
		n=$(cat ${ds}.list | wc -l)
		i=1
		while read line ; do
			# make symlinks on background to speed up the process 
			# stackoverflow: how-to-get-pid-of-background-process
			(split_dataset_bg $basedir $line)&
			pid=$!
			sleep 0.01
		done < ${ds}.list
		# stackoverflow: how-to-wait-in-bash-for-several-subprocesses-to-finish-and-return-exit-code-0
		wait $pid && echo "10 sec to finish..." && sleep 10
		echo
	done
}

# HTKBook's section 3.1.2 - dict (without HDMan)
create_dict() {
	echo -n "[FB] Creating phonetic dict (HDMan-like)..."

	# get all transcriptions
	i=1
	n=$(cat ${1}.tmp | wc -l)
	while read txtfile ; do
		# write every word of each transcription to a file
		for word in $(cat ${txtfile}.txt) ; do
			echo $word >> wlist.tmp
		done
	done < ${1}.tmp

	# remove repeated words and sort words in alphabetical order
	# also remove the bloody annoying windows CR char () 
	# and the mysterious latin-1 <94> char
	# https://superuser.com/questions/194668/grep-to-find-files-that-contain-m-windows-carriage-return
	# https://www.cyberciti.biz/faq/sed-remove-all-except-digits-numbers/
	sort wlist.tmp | sed 's/[^a-z -]*//g' | uniq > ${HTK_PROJECT_DIR}/etc/wordlist.txt

	echo -e "\t\tApplying G2P converter..."
	# check whether g2p software is compiled
	if [ ! -f ${G2P_DIR}/TestG2P.class ] ; then
		cd $G2P_DIR
		javac -cp ".:g2plib.jar" TestG2P.java
		cd -
	fi

	rm -f dic.tmp
	cur_dir=$(pwd)

	# apply g2p conversion
	cd ${G2P_DIR}/..
	while read word ; do
		java -cp ".:g2p/g2plib.jar" g2p.TestG2P $word >> ${cur_dir}/dic.tmp
	done < ${HTK_PROJECT_DIR}/etc/wordlist.txt
	cd -

	echo -e "sil\tsil"   >> dic.tmp # append sil
	echo -e "<s>\tsil"   >> dic.tmp # append sil
	echo -e "</s>\tsil"  >> dic.tmp # append sil
	echo -e "sp\tsp"     >> dic.tmp # append sp

	# HDMan ERROR [+1452]  ReadDictProns: word acaso out of order in dict etc/dictionary.dic
	# stackoverflow: how-to-sort-a-text-file-according-to-character-code-or-ascii-code-value
	LC_ALL=C sort dic.tmp > ${HTK_PROJECT_DIR}/etc/dictionary.dic
}

# HTKBook's section 3.1.4 - creating the transcription files 
create_trans() {
	echo "[HLEd] Creating transcription files (words.mlf)..."
	echo "#!MLF!#" > words.mlf
	while read line ; do
		echo "\"*/$(basename $line).lab\"" >> words.mlf
		for word in $(cat ${line}.txt) ; do
			# https://www.cyberciti.biz/faq/sed-remove-all-except-digits-numbers/
			echo $word | sed 's/[^a-z -]*//g' >> words.mlf
		done
		echo "." >> words.mlf
	done < ${1}.list

	mv words.mlf ${HTK_PROJECT_DIR}/etc

	# without short pause (sp)
	HLEd \
		-l '*' \
		-d ${HTK_PROJECT_DIR}/etc/dictionary.dic \
		-i ${HTK_PROJECT_DIR}/etc/phones0.mlf \
		${HTK_PROJECT_DIR}/util/mkphones.led \
		${HTK_PROJECT_DIR}/etc/words.mlf

	# with short pause (sp)
	HLEd \
		-l '*' \
		-d ${HTK_PROJECT_DIR}/etc/dictionary.dic \
		-i ${HTK_PROJECT_DIR}/etc/phones_sp.mlf \
		${HTK_PROJECT_DIR}/util/mkphones_sp.led \
		${HTK_PROJECT_DIR}/etc/words.mlf
}

# HTKBook's section 3.1.5 - coding the data
create_mfc() {
	argv=($1 $2)
	for ds in ${argv[@]} ; do
		# rewrite list in order to avoid messing with the original, hard linked basedir
		find "${HTK_PROJECT_DIR}/wav/${ds}" -name "*.wav" | sed 's/.wav$//g' > ${ds}.list
		echo -n "[HCopy] Creating mfc for $ds files..."
		n=$(cat ${ds}.list | wc -l)
		i=1
		while read line ; do
			wav="${line}.wav"
			mfc="${line}.mfc"
			# execute HCopy on background to speed things up (codetr.scp avoided)
			(HCopy -T 1 -C ${HTK_PROJECT_DIR}/conf/edaz.conf $wav $mfc > /dev/null)&
			sleep 0.03
		done < ${ds}.list
		echo
	done
	sleep 0.5
}

##################################################
### HTKBook                                    ###
### Chapter 3: A Tutorial Example of Using HTK ###
### Section 3.1: Data Preparation              ###
##################################################

if [[ $SPLIT_RANDOM == true ]] ; then
	# sort -R would have solved this crap (while read line)
	find ${AUDIO_DATA_DIR} -name '*.wav' | sed 's/.wav//g' |\
			while read line; do echo "$RANDOM $line" ; done |\
			sort | awk '{print $NF}' > filelist.tmp
	
	ntotal=$(cat filelist.tmp | wc -l)
	ntest=$((ntotal/10))     # 10% test
	ntrain=$((ntotal-ntest)) # 90% train
	
	head -n $ntrain filelist.tmp > train.list
	tail -n $ntest  filelist.tmp > test.list
else
	echo "warning: using only '$TEST_DIR' for test"
	find $AUDIO_DATA_DIR -name '*.wav' | sed 's/.wav//g' > filelist.tmp
	find $AUDIO_DATA_DIR -name '*.wav' | grep -v "${TEST_DIR}" | sed 's/.wav//g' > train.list
	find ${AUDIO_DATA_DIR}/${TEST_DIR} -name '*.wav' | sed 's/.wav//g' > test.list

	ntrain=$(wc -l train.list | awk '{print $1}')
	ntest=$(wc -l test.list | awk '{print $1}')
fi

split_dataset "train" "test"
create_dict   "filelist"     # HTKBook's sec 3.1.2 - dict (without HDMan)
create_trans  "train"        # HTKBook's sec 3.1.4 - creating the transcription files 
create_mfc    "test" "train" # HTKBook's sec 3.1.5 - coding the data

(play -q doc/KDE-Im-Sms.ogg)&
echo -e "\e[1mDone!\e[0m"
rm train.list test.list *.tmp
### EOF ###
