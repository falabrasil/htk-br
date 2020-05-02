echo "MAP Transformation ..."
mkdir MAP
AM=$1

HERest -C util/map.config -s stats -t 250 150 1000 -A -D -T 1 -u mvwp -I MLF -S mfc_train.list -H "$AM"/MMF -M MAP -h '*/*.%*' "$AM"/tiedlist

cp "$AM"/tiedlist MAP
mv stats MAP


