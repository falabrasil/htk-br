#!/bin/bash
#
# a lazy script to run all the other scripts 
#
# Copyright Grupo FalaBrasil (2018)
# Federal University of Pará (UFPA)
#
# Author: April 2018
# Cassio Batista - cassio.batista.13@gmail.com
#
# Reference:
# http://htk.eng.cam.ac.uk/docs/docs.shtml

source fb_config.sh

./fb_00_create_envtree.sh 
./fb_01_dataprep.sh 
./fb_02_create_monoph_hmm.sh 
./fb_03a_create_triph_hmm.sh 
./fb_03b_increase_gaussmix.sh 
./fb_04_recog_eval.sh 
