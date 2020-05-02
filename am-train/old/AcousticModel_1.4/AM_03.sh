###### Implementa Tying de Estados por Árvore #######

mkdir hmmsTree

# copia a árvore de decisão

cp util/bestTree.hed tree.hed

echo "Fazendo Tying dos estados..."

HHEd -B -H hmms22/macros -H hmms22/hmmdefs -M hmmsTree tree.hed trifone
HERest -B -I wintri.mlf -t 250.0 150.0 1000.0  -S mfc_train.list -H hmmsTree/macros -H hmmsTree/hmmdefs -M hmmsTree tiedlist
HERest -B -I wintri.mlf -t 250.0 150.0 1000.0  -S mfc_train.list -H hmmsTree/macros -H hmmsTree/hmmdefs -M hmmsTree tiedlist
HERest -B -I wintri.mlf -t 250.0 150.0 1000.0  -S mfc_train.list -H hmmsTree/macros -H hmmsTree/hmmdefs -M hmmsTree tiedlist
HERest -B -I wintri.mlf -t 250.0 150.0 1000.0  -S mfc_train.list -H hmmsTree/macros -H hmmsTree/hmmdefs -M hmmsTree tiedlist

echo "Fim do Treino !!!"
