#!/bin/bash
CORPUS=/diretorio/corpus/
TRAIN="lista de treino"
TEST="lista de teste" 
TXT="lista de arquivos txts"

echo Criando listas de treino e teste ...

# copia lista de arquivos (treino e teste)
cp $TRAIN .
cp $TEST .
cp $TXT .

echo
