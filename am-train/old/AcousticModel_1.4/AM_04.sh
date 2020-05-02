########## Incrementa o numero de Gauss/Mix ################

echo
echo "incrementando o número de Gauss/Mix... "
echo
mkdir 2G
mkdir hmms

echo "Incrementando --> 2 Gauss/mix ..."
HHEd -H hmmsTree/macros -H hmmsTree/hmmdefs  -M 2G util/mix2.hed tiedlist
HERest -u tmvw -I wintri.mlf -t 250 150 1000 -S mfc_train.list -H 2G/macros -H 2G/hmmdefs -M hmms tiedlist
HERest -u tmvw -I wintri.mlf -t 250 150 1000 -S mfc_train.list -H hmms/macros -H hmms/hmmdefs -M 2G tiedlist
echo

# Alterar o número de gaussianas para o valor desejado

for i in `seq 3 10`
do

mkdir $i"G"
let p="$i - 1"

echo "Incrementando --> $i Gauss/mix ..."
HHEd -H $p"G"/macros -H $p"G"/hmmdefs  -M $i"G" util/mix$i.hed tiedlist
HERest -u tmvw -I wintri.mlf -t 250 150 1000 -S mfc_train.list -H $i"G"/macros -H $i"G"/hmmdefs -M hmms tiedlist
HERest -u tmvw -I wintri.mlf -t 250 150 1000 -S mfc_train.list -H hmms/macros -H hmms/hmmdefs -M $i"G" tiedlist
echo
done

