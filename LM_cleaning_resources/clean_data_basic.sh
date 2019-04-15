#To grep these two lines
#<LRLP_MORPH_TOKENIZED_SOURCE>Вся тема перетекла в измены !</LRLP_MORPH_TOKENIZED_SOURCE>
#<LRLP_POSTAG_SOURCE>word word word word word punct</LRLP_POSTAG_SOURCE>
set -e
lang=il9
storage=/mnt/scratch06/tmp/baskar/Lorelei/il9_lms/
lmA=/mnt/matylda4/glembek/LORELEI/tasks/EVAL_2018-07/download/elisa.il9-eng.eval.y3r1.v1.xml.eng.gz
lmB=/mnt/matylda4/glembek/LORELEI/tasks/EVAL_2018-07/download/elisa.il9-eng.eval.y3r1.v1.xml.il9.gz
lmC=/mnt/matylda4/glembek/LORELEI/tasks/EVAL_2018-07/download/elisa.il9.package.y3r1.v1.tgz
lmD=/mnt/matylda4/glembek/LORELEI/tasks/EVAL_2018-07/download/elisa.il9.package.y3r1.v1.tgz
lmE=/mnt/matylda4/glembek/LORELEI/tasks/EVAL_2018-07/download/rpi_gazetteers/il9-eng.gaz.v0.tsv 
lmF=/mnt/matylda4/glembek/LORELEI/tasks/EVAL_2018-07/download/rpi_gazetteers/il9.name.gazetteers.rpi.v1.tsv
lmB=/mnt/matylda6/baskar/experiments/kaldi/Lorelei/Multilingual/bmk/elisa.il9.package.y3r1.v1/elisa.il9.y3r1.v1.xml.gz
lmB=/mnt/matylda6/baskar/experiments/kaldi/Lorelei/Multilingual/bmk/elisa.il10.package.y3r1.v1/elisa.il10.y3r1.v1.xml.gz
# Step1: clean the data by mapping the token and tag and replacing punct by <eps>
mkdir -p $storage
for lm in $lmB; do
    cd $storage
    name=`basename $lm`
    zgrep "<LRLP_MORPH_TOKENIZED_SOURCE>" $lm > ${name}.token.gz
    zgrep "<LRLP_POSTAG_SOURCE>" $lm > ${name}.tag.gz
    split -l 1000000 "${name}.token.gz" "${name}.token.part-"
    split -l 1000000 "${name}.tag.gz" "${name}.tag.part-"
    cd -
    for i in `ls $storage/${name}.token.part-*`; do
        new_name=$(basename $i)
        split_name=`echo $new_name | awk -F"-" '{print $NF}'`
        echo $split_name
        sed -i "s|<LRLP_POSTAG_SOURCE>||g;s|</LRLP_POSTAG_SOURCE>||g" $storage/${name}.tag.part-${split_name}
        sed -i "s|<LRLP_MORPH_TOKENIZED_SOURCE>||g;s|</LRLP_MORPH_TOKENIZED_SOURCE>||g" $storage/${name}.token.part-${split_name}
        python local/remove_punc_tags.py $storage/${name}.token.part-${split_name} $storage/${name}.tag.part-${split_name} \
            $storage/${name}.token.filt${split_name}.txt
        sed -i "s|<eps>||g;s|<unkn>||g" $storage/${name}.token.filt${split_name}.txt
        awk '{print tolower($0)}' $storage/${name}.token.filt${split_name}.txt \
            | perl -C -MHTML::Entities -lpe 'decode_entities($_);' \
            | sed 's@[[:punct:]]@ @g' \
            | sed 's@^ \+@ @' \
            | sed 's@^[[:digit:]]\+ @@' \
            | sed 's@^Re @@' \
            | sed 's@\([[:digit:]]\)@@g' > $storage/${name}.token.normit1.filt${split_name}.txt
        sed -i '/^$/d' $storage/${name}.token.normit1.filt${split_name}.txt
        sed -i '/^ \+$/d' $storage/${name}.token.normit1.filt${split_name}.txt
        sed -i "s| [a-z] ||g;s|^ \+||g;s| \+$||g" $storage/${name}.token.normit1.filt${split_name}.txt
        sed -i "s|  \+| |g" $storage/${name}.token.normit1.filt${split_name}.txt
        bash local/punctuations.sh $storage/${name}.token.normit1.filt${split_name}.txt
    done
done


# Step2: Tokenization of text


exit 0
<<"over"
awk -F, '(length($0)<=100 && length($0)>=10)' /mnt/scratch06/tmp/baskar/Lorelei/elisa.rus.y2r2.v1.filt.txt > /mnt/scratch06/tmp/baskar/Lorelei/elisa.rus.y2r2.v1.filt.10-100.txt
awk -F, '(length($0)<=200 && length($0)>=101)' /mnt/scratch06/tmp/baskar/Lorelei/elisa.rus.y2r2.v1.filt.txt > /mnt/scratch06/tmp/baskar/Lorelei/elisa.rus.y2r2.v1.filt.101-200.txt
awk -F, '(length($0)<=1000 && length($0)>=201)' /mnt/scratch06/tmp/baskar/Lorelei/elisa.rus.y2r2.v1.filt.txt > /mnt/scratch06/tmp/baskar/Lorelei/elisa.rus.y2r2.v1.filt.201-1000.txt
awk -F, '(length($0)<=5000 && length($0)>=1001)' /mnt/scratch06/tmp/baskar/Lorelei/elisa.rus.y2r2.v1.filt.txt > /mnt/scratch06/tmp/baskar/Lorelei/elisa.rus.y2r2.v1.filt.1001-5000.txt
over
path=/mnt/scratch06/tmp/baskar/Lorelei/
code=elisa.rus.y2r2.v1.filt
<<"over"
cd $path
i=0
for file in 1001-5000 201-1000 50001-15000 "charac5.1k2100k"; do 

cat $code.$file.txt | sed 's@\.\+@ @g' \
	| perl -C -MHTML::Entities -lpe 'decode_entities($_);' \
	| perl -C -MHTML::Entities -lpe 'decode_entities($_);' \
	| sed 's@[[:punct:]]@ @g' \
	| sed 's@^ \+@@' \
	| sed 's@^[[:digit:]]\+ @@' \
	| sed 's@^Re @@' \
	| sed 's@\([[:digit:]]\)@\1 @g' \
	| sed 's@ \+@ @g' \
	| awk '(NF<=500 && NF >= 1){print}' | sort -u \
	> /mnt/scratch06/tmp/baskar/Lorelei/elisa.rus.y2r2.v1.filt.b${i}.txt
i=$((i+1))
done
cd -
over
#cd $path
#a=(`wc -l ${code}.b2.txt`) ; lines=1000000 ; split -l $lines -d  ${code}.b2.txt ${code}.b2_

#cd -
