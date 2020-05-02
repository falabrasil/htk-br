#!/bin/bash
#
# This script sets the config variables for training an acoustic model with HTK
# This script must be sourced before proceeding with fb_0x recipes 
#
# Copyright Grupo FalaBrasil (2018)
# Federal University of Pará (UFPA)
#
# Author: July 2018
# Cassio Batista - cassio.batista.13@gmail.com
#
# Reference:
# HTKBook (http://htk.eng.cam.ac.uk/docs/docs.shtml)
# Chapter 3: A Tutorial Example of Using HTK 

# https://stackoverflow.com/questions/2683279/how-to-detect-if-a-script-is-being-sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
	echo "error: you should use the 'source' command to execute this file."
	exit 1
fi

export DEGUB=false

# the path for a folder to host your project
export HTK_PROJECT_DIR="${HOME}/htk_am_train"

# folder that contains all your audio base (wav + transcript.)
export AUDIO_DATA_DIR="${HOME}/falabrasil/bases"

# path to grapheme to phoneme converter in Java
export G2P_DIR="${HOME}/falabrasil/github/phonetic-dicts/g2p"

# path to language model file
export LM_FILE="${HOME}/falabrasil/lapsam.lm"

# set TRUE  for splitting data set randomly
# set FALSE to use LaPSBM as test set only
export SPLIT_RANDOM=false
export TEST_DIR="frases16k"

# the maximum number of gaussians to increase
# this value must be a power of 2 (2, 4, 8, 16, 32, 64, 128, 256, ...)
export MAX_GAUSS=16

echo "well done, $(whoami)!"
### EOF ###
