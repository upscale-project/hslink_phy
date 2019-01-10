#################################################
#
# Copyright (c) 2017 Stanford University. All rights reserved.
# 
# The information and source code contained herein is the 
# property of Stanford University, and may not be disclosed or
# reproduced in whole or in part without explicit written 
# authorization from Stanford University. Contact bclim@stanford.edu for details.
# 
# Filename   : Makefile
# Description: Runs test benches
# 
#################################################

#SPARAMS ?= ../data/TEC_Whisper42p8in_Nelco6_THRU_C8C9.s4p
#SPARAMS ?= ../data/TEC_Whisper42p8in_Meg6_THRU_C8C9.s4p
SPARAMS ?= ../data/peters_01_0605_B12_thru.s4p

MATLAB = /hd/cad/mathworks/matlab.r2017b/bin/matlab

.PHONY: all generate compile sim compare clean view

all: analyze generate

analyze:
	# generates the system model
	$(MATLAB) -nodesktop -nodisplay -nosplash -r "model_channel('$(SPARAMS)'); quit;"

generate:
	# generate channel model
	./generate.py

clean:
	# remove generated files
	rm -f channel.v sys.txt freq.txt
