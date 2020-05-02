$Arq = "hmmlist.txt";

select(STDOUT);

open(Arq);
@conteudo = <Arq>;

$n = 0;
$i = 0;

`echo "CL trifone" >> mktri.hed`;

do {

@word = split(/ +/,$conteudo[$n]);
chop $word[$#word];

`echo "TI T_$word[0] {(*-$word[0]+*,$word[0]+*,*-$word[0]).transP}" >> mktri.hed`;

$n++;

} until ($n > $#conteudo);

