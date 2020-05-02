######## Cria o Modelo de Linguagem ##########

#conjunto de treino e teste
TRAIN=databases/train.xml
TEST=databases/test.xml

#Vocabulario
VOC=seuvocabulario.voc

#N-Gram
N=2

cp $VOC vocabulary.txt

A=300000
B=500000

mkdir Ngrams.0
LNewMap -f WFC BRASIL empty.wmap
echo

LGPrep -T 1 -a $A -b $B -d Ngrams.0 -n $N -s "LanGModel" empty.wmap $TRAIN
echo

mkdir Ngrams.1

LGCopy -T 1 -b $B -d Ngrams.1 Ngrams.0/wmap Ngrams.0/gram.*

mkdir Ngrams.2

LSubset -T 1 Ngrams.0/wmap vocabulary.txt Ngrams.2/model.wmap

LFoF -T 1 -n $N -f 32 Ngrams.2/model.wmap Ngrams.2/model.fof Ngrams.1/data.* 

echo "!!UNK" >> vocabulary.txt

### Criando modelo de linguagem ###
LBuild -T 1 -c 2 1 -c 3 1 -f TEXT -n $N Ngrams.2/model.wmap Ngrams.2/bigram Ngrams.1/data.* 

###  Criando Rede de Palavras  ###
#PS: utilizado apenas para N=2
HBuild -A -T 1 -s "<s>" "</s>" -n Ngrams.2/bigram vocabulary.txt network_"$VOC"

### Calculando Perplexidade ###

LPlex -u -n $N -t Ngrams.2/bigram "$TEST" 

