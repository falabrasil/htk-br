### Script for Speaker Adaptation ###

## Cria o MLF a nível de fonema e depois em nível de trifone.

HLEd -l '*' -d ../dictionary.dic -i phonesp.mlf scripts/mkphonesSP.led words.mlf
HLEd -n temp -l '*' -i MLF scripts/mkCrossWord.led phonesp.mlf

rm temp
rm phonesp.mlf
