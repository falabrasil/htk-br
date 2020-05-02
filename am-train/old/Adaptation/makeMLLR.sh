### Script for Speaker Adaptation ###

## Realiza a adaptação MLLR

# Recebe a pasta onde está o Modelo acústico como parâmetro (usa o MMF e tiedlist)
AM=$1

mkdir MLLR
mkdir hmmAdapt
cp util/global hmmAdapt/
cp "$AM"/stats .


# Cria árvore de regressão de classes  
HHEd -B -H "$AM"/MMF -M hmmAdapt/ util/regtree.hed "$AM"/tiedlist 

echo
echo
echo "Global Adaptation ..."

HERest -B -A -D -T 1 -C util/adapt.conf -S mfc_train.list -u a -I MLF -H "$AM"/MMF -J hmmAdapt -K hmmAdapt -h '*/*.%*' "$AM"/tiedlist 


echo
echo
echo "Regression Class ..."


HERest -B -a -A -T 1 -C util/adapt.rc -u a -S mfc_train.list -s stats -I MLF -H hmmAdapt/MMF.m -J hmmAdapt -K hmmAdapt mllr -h '*/*.%*' "$AM"/tiedlist

cp hmmAdapt/*.mllr MLLR 
cp "$AM"/tiedlist MLLR
mv stats MLLR/
mv MLLR/MMF.m.mllr MLLR/MMF

echo "------- MLLR DONE -------- "

