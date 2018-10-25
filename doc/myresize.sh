#!/bin/bash

if test $# -ne 2
then
	echo "Usage: $(basename $0) <file_in> <scale_factor>"
	echo -e "<file_in>      must be a dia diagram (.dia)"
	echo -e "<scale_factor> is a percentage interger between 0 and 100"
	exit 1
fi

if [[ ! -f $1 ]] 
then
	echo "Error: <file_in> must be a .dia file"
	exit 1
elif [[ $2 -lt 1 || $2 -gt 99 ]]
then
	echo "Error: <scale_factor> must be in (0,100) interval "
	exit 1
fi

ftype=$(file $1 | awk '{print $2}')
if [[ "$ftype" != "gzip" ]]
then
	echo "Error: '$1' is not a valid dia file"
	exit 1
fi

# get diagram filename
fname=$(echo $1 | sed 's/\./ /g' | awk '{print $1}')

# export as eps
dia ${fname}.dia -e ${fname}.eps

# convert eps to png
sam2p ${fname}.eps ${fname}.png

# get dimenstions
width=$(file ${fname}.png | cut -d ' ' -f 5)
height=$(file ${fname}.png | cut -d ' ' -f 7 | tr -d ',')

# reduce dimension to 60% on both axis
dimension="$(echo "$2*$width/100" | bc)x$(echo "$2*$height/100" | bc)"
convert ${fname}.png -resize $dimension ${fname}.jpg

# show results
convert ${fname}.png -print 'PNG size: %wx%h\n' /dev/null
convert ${fname}.jpg -print 'JPG size: %wx%h ' /dev/null
echo "-> ${fname}.jpg"

# remove useless files
rm ${fname}.eps ${fname}.png

### EOF ###
