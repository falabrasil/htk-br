####### Estima o Modelo Acústico - Monofone ############

# copia lista de fones
cp ./util/phones.list hmmlist.txt

mkdir hmms0

echo "Criando arquivos MLF..."
java -jar scripts/TxtToMLF.jar Txts.list
HLEd -l '*' -d dictionary.dic -i phones0.mlf util/mkphones.led words.mlf
HLEd -l '*' -d dictionary.dic -i phonesp.mlf util/mkphonesSP.led words.mlf
echo

# renomeia os arquivos da lista de ".wav" para ".mfc"
cat wav_train.list | sed s/wav/mfc/g > mfc_train.list
cat wav_test.list | sed s/wav/mfc/g > mfc_test.list

echo  Criando  um prototipo de HMM com 5 estados usando 1 Gauss/Mix de dimensao 39.
java -cp . ufpa.curupira.scripts.htk.CreateHMMPrototype 5 1 39 MFCC_0_D_A proto > hmms0/proto.hmm


echo "Computando Média e Variâncias globais ..."
HCompV -C confs/hcomp.conf -f 0.01 -m -S mfc_train.list -M hmms0 hmms0/proto.hmm

echo Criando hmms para cada fone...
./scripts/make-proto.sh

echo
echo "Criando hmms.mlf, hmmdefs e macros para treino ..."
echo
# Criando hmms.mlf
echo "" > concatenade.hed
HHEd -w hmms.mlf -d hmms0/ concatenade.hed hmmlist.txt

# Criando hmmdefs e macros

x=`wc -l hmms.mlf | awk '{print $1}' `
let y="$x - 3"
tail -n $y  hmms.mlf > temp
mv temp ./hmms0/hmmdefs

head -n 3 hmms.mlf > hmms0/temp
cat hmms0/temp hmms0/vFloors > hmms0/macros

mkdir hmms1
echo "HERest - 1a reestimação ..."
HERest -I phones0.mlf -t 250.0 150.0 1000 -S mfc_train.list -H hmms0/macros -H hmms0/hmmdefs -M hmms1 hmmlist.txt  
echo
echo

mkdir hmms2
echo "HERest - 2a reestimação ..."
HERest -I phones0.mlf -t 250.0 150.0 1000 -S mfc_train.list -H hmms1/macros -H hmms1/hmmdefs -M hmms2 hmmlist.txt
echo 
echo

mkdir hmms3
echo "HERest - 3a reestimação ..."
HERest -I phones0.mlf -t 250.0 150.0 1000 -S mfc_train.list -H hmms2/macros -H hmms2/hmmdefs -M hmms3 hmmlist.txt
echo 
echo 

echo "Adicionando short-pause (sp) ..."
echo
mkdir hmms4
cp hmms3/* hmms4
mkdir hmms5
echo "sp" >> hmmlist.txt

java -jar scripts/Makesp.jar hmms4/hmmdefs

HHEd -H hmms4/macros -H hmms4/hmmdefs -M hmms5/ util/sil.hed hmmlist.txt

mkdir hmms6
echo "HERest - 4a reestimação ..."
HERest -I phonesp.mlf -t 250.0 150.0 1000 -S mfc_train.list -H hmms5/macros -H hmms5/hmmdefs -M hmms6 hmmlist.txt
echo

mkdir hmms7
echo "HERest - 5a reestimação ..."
HERest -I phonesp.mlf -t 250.0 150.0 1000 -S mfc_train.list -H hmms6/macros -H hmms6/hmmdefs -M hmms7 hmmlist.txt
echo

mkdir hmms8
echo "HERest - 6a reestimação ..."
HERest -I phonesp.mlf -t 250.0 150.0 1000 -S mfc_train.list -H hmms7/macros -H hmms7/hmmdefs -M hmms8 hmmlist.txt
echo

mkdir hmms9
echo "HERest - 7a reestimação ..."
HERest -I phonesp.mlf -t 250.0 150.0 1000 -S mfc_train.list -H hmms8/macros -H hmms8/hmmdefs -M hmms9 hmmlist.txt
echo

mkdir hmms10
echo "HERest - 8a reestimação ..."
HERest -I phonesp.mlf -t 250.0 150.0 1000 -S mfc_train.list -H hmms9/macros -H hmms9/hmmdefs -M hmms10 hmmlist.txt
echo

mkdir hmms11
echo "HERest - 9a reestimação ..."
HERest -I phonesp.mlf -t 250.0 150.0 1000 -S mfc_train.list -H hmms10/macros -H hmms10/hmmdefs -M hmms11 hmmlist.txt
echo

mkdir hmms12
echo "HERest - 10a reestimação ..."
HERest -I phonesp.mlf -t 250.0 150.0 1000 -S mfc_train.list -H hmms11/macros -H hmms11/hmmdefs -M hmms12 hmmlist.txt
echo

mkdir hmms13
echo "HERest - 11a reestimação ..."
HERest -I phonesp.mlf -t 250.0 150.0 1000 -S mfc_train.list -H hmms12/macros -H hmms12/hmmdefs -M hmms13 hmmlist.txt
echo

mkdir hmms14
echo "HERest - 12a reestimação ..."
HERest -I phonesp.mlf -t 250.0 150.0 1000 -S mfc_train.list -H hmms13/macros -H hmms13/hmmdefs -M hmms14 hmmlist.txt
echo


# Realizando Alinhamento forçado
# PS: Não recomendado para o spoltech e OGI (muitos arquivos defeituosos)

#echo "Realinhando dados de treino..."
#HVite -l '*' -o SWT -b silence -a -H hmms14/macros -H hmms14/hmmdefs -i aligned.mlf -m -t 250.0 -y lab -I words.mlf -S mfc_train.list newdic.dic hmmlist.txt 
echo

#mkdir hmms15
#echo "HERest - 13a reestimação ..."
#HERest -I aligned.mlf -t 250.0 150.0 1000 -S mfc_train.list -H hmms14/macros -H hmms14/hmmdefs -M hmms15 hmmlist.txt
echo

#mkdir hmms16
#echo "HERest - 14a reestimação ..."
#HERest -I aligned.mlf -t 250.0 150.0 1000 -S mfc_train.list -H hmms15/macros -H hmms15/hmmdefs -M hmms16 hmmlist.txt
echo

#mkdir hmms17
#echo "HERest - 15a reestimação ..."
#HERest -I aligned.mlf -t 250.0 150.0 1000 -S mfc_train.list -H hmms16/macros -H hmms16/hmmdefs -M hmms17 hmmlist.txt
echo

