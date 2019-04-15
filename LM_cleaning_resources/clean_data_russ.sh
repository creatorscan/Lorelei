#To grep these two lines
#<LRLP_MORPH_TOKENIZED_SOURCE>Вся тема перетекла в измены !</LRLP_MORPH_TOKENIZED_SOURCE>
#<LRLP_POSTAG_SOURCE>word word word word word punct</LRLP_POSTAG_SOURCE>


glembek=/mnt/matylda4/glembek/LORELEI/download/ELISA/dryruns/2017.06.05/rus/JMIST
storage=/mnt/scratch06/tmp/baskar/Lorelei/Russian
lm1=$glembek/elisa.rus-eng.dev.y2r2.v1.xml.gz
lm2=$glembek/elisa.rus-eng.eval.y2r2.v1.xml.gz
lm3=$glembek/elisa.rus-eng.test.y2r2.v1.xml.gz
lm4=$glembek/elisa.rus-eng.train.y2r2.v1.xml.gz
lm5=$glembek/elisa.rus.y2r2.v1.xml.gz
gazzlm=/mnt/matylda4/glembek/LORELEI/tasks/EVAL_2017-06_RussianDryrun/download/RPI/rus_gaz/output.rus
mkdir -p $storage

tok=elisa.rus.y2r2.v1_token
tag=elisa.rus.y2r2.v1_tags
lang=data_russian/lang
lang_test=data_russian/lang_test

cd $storage
cp $lm5 $storage
lm5=$storage/elisa.rus.y2r2.v1.xml.gz
gunzip $lm5
lm5=$storage/elisa.rus.y2r2.v1.xml
grep "<LRLP_TOKENIZED_SOURCE>" $lm5 > ${tok}.txt
grep "<LRLP_POSTAG_SOURCE>" $lm5 > ${tag}.txt
cat ${tok}.txt | perl -C -MHTML::Entities -lpe 'decode_entities($_);' \
	| sed 's@[[:punct:]]@ @g' \
    | sed 's@^ \+@ @' \
	| sed 's@^[[:digit:]]\+ @@' \
	| sed 's@^Re @@' \
	| sed 's@\([[:digit:]]\)@\1 @g' > ${tok}_filt.txt

#the file is split incase of huge text file
#change the split option to "1" from "1000000" for small file
split -l 100000 "${tok}.txt" "${tok}.part-"
split -l 100000 "${tag}.txt" "${tag}.part-"
cd -

for i in `ls $storage/${tok}.part-*`; do
  name=$(basename $i)
  split_name=`echo $name | sed "s|${tok}.part-||g"`
  echo $split_name
  sed -i "s|<LRLP_TOKENIZED_SOURCE>||g;s|</LRLP_TOKENIZED_SOURCE>||g" $storage/${tok}.part-${split_name}
  sed -i "s|<LRLP_POSTAG_SOURCE>||g;s|</LRLP_POSTAG_SOURCE>||g" $storage/${tag}.part-${split_name}
  python local/remove_punc_tags.py $storage/${tok}.part-${split_name} $storage/${tag}.part-${split_name} $storage/${tok}_filt${split_name}.txt
  python local/remove_hex_codes.py $storage/${tok}_filt${split_name}.txt $storage/${tok}_filt${split_name}_cleaned.txt 
done

python local/remove_hex_codes.py $gazzlm $storage/${tok}_gazz_cleaned.txt
cat $storage/${tok}_filt*_cleaned.txt > $storage/${tok}_cleaned.txt



# Finally clearing up the space
rm $storage/${tok}_filt*_cleaned.txt
rm $storage/${tok}_filt*.txt
