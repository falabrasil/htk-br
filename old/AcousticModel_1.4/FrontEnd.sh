# Copia e renomeia os arquivos ".wav" para ".mfc" para serem usados como arquivos de entrada do HCopy

echo criando lista de arquivos "mfcc" ...
cat wav_train.list | perl -e 'while (<>) { chomp; s/\.wav$//; $x=$_; print "$x.wav $x.mfc\n"; }' > wav_mfc_train.list
cat wav_test.list | perl -e 'while (<>) { chomp; s/\.wav$//; $x=$_; print "$x.wav $x.mfc\n"; }' > wav_mfc_test.list

echo
echo Extraindo parametros....
echo

# Extrai os parametros dos arquivos de voz.
HCopy -A -C confs/hcopy-wav.conf -S wav_mfc_train.list
HCopy -A -C confs/hcopy-wav.conf -S wav_mfc_test.list

