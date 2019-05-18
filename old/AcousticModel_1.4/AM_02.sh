############ Cria Trifones #############

echo
echo "Criando Trifones ..."

## CrossWords Trifones
##HLEd -n trifone -l '*' -i wintri.mlf util/mkCrossWord.led phonesp.mlf

##InternalWord Trifones
HLEd -n trifone -l '*' -i wintri.mlf util/mktri.led phonesp.mlf

# O comando acima cria uma lista de trifones, porém quase sempre é insuficiente
# copia nova lista de trifones

cp util/intWordTrifones.list trifone
#cp util/trifonesCrossWord.list trifone


echo "Clonando Trifones ..."
mkdir hmms18
perl scripts/MAmktie.perl

#PS: alterar o diretório abaixo (hmms14) caso o realinhamento tenha sido feito
HHEd -B -H hmms14/macros -H hmms14/hmmdefs -M hmms18 mktri.hed hmmlist.txt
rm mktri.hed

echo
echo "Reestimando trifones..."
mkdir hmms19
HERest -B -I wintri.mlf -t 250.0 150.0 1000.0 -s stats -S mfc_train.list -H hmms18/macros -H hmms18/hmmdefs -M hmms19 trifone

echo
echo "Reestimando trifones...."
mkdir hmms20
HERest -B -I wintri.mlf -t 250.0 150.0 1000.0 -s stats -S mfc_train.list -H hmms19/macros -H hmms19/hmmdefs -M hmms20 trifone

echo
echo "Reestimando trifones....."
mkdir hmms21
HERest -B -I wintri.mlf -t 250.0 150.0 1000.0 -s stats -S mfc_train.list -H hmms20/macros -H hmms20/hmmdefs -M hmms21 trifone

echo
echo "Reestimando trifones......"
mkdir hmms22
HERest -B -I wintri.mlf -t 250.0 150.0 1000.0 -s stats -S mfc_train.list -H hmms21/macros -H hmms21/hmmdefs -M hmms22 trifone

