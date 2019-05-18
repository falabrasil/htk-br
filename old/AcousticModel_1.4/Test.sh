# Exemplos de decodificação

# Utilizando o HVite
HVite -T 1 -i hviteout.txt -H hmms18/macros -H hmms18/hmmdefs -S mfc_test.list -w LangModel newdic.dic trifone

# Utilizando o HDecode
HDecode -T 1 -C confs/hvite.conf  -t 250.0 150.0 -i hedout.txt -H 6G/macros -H 6G/hmmdefs -S mfc_test.list -w bigram dictionary.dic tiedlist

# Utilizando o AVite
AVite -C confs/hvite.conf -T 1 -o FILE -i avitecout.txt -H 6G/macros -H 6G/hmmdefs -S wav_test.list -w network dictionary.dic tiedlist

# Gerando Lattices com o HVite
HVite -T 1 -n 4 20 -i lattices/bigram.out -H 8G/macros -H 8G/hmmdefs -S mfc_test.list -z lat -l lattices/ -w network dictionary.dic tiedlist 

# Realizando Rescoring com trigramas
HLRescore -T 1 -A -D -i trigram.out -n lms/trigram_corpora.arpa -f dictionary.dic -S lattices.list

# Analisando resultados
HResults -I words.mlf wordlist.txt hviteout.txt
