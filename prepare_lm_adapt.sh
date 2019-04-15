#!/bin/bash
set -e
#/mnt/scratch06/tmp/baskar/Lorelei/Tigrinya
tr_text=$1
#data/train_sp/text
lm_text=$2
#$scratch/tigrinya2_token_filt_cleaned.txt
mult_text=$3
dict=$4
lm=$5
lang=$6
lang_test=$7
words=$dict/vocab


if [ ! -f $words ]; then
mkdir -p $dict
cut -f2- -d " "  $tr_text | sed "s| |\n|g" | sort -u > $dict/vocab_train
cut -f2- -d " "  $mult_text | sed "s| |\n|g" | sort -u > $dict/vocab_gazz
text2wfreq < $lm_text > ${lm_text}.wfreq
exit 0
wfreq2vocab -top 40000 < ${lm_text}.wfreq | grep -v "#" > ${lm_text}.vocab
#sed -i '/[A-Z,a-z]/d' ${lm_text}.vocab
cat ${lm_text}.vocab $dict/vocab_train $dict/vocab_gazz | sort -u > $words
echo "check vocab for mistakes"
exit 0
fi

# prepare new dictionary with all vocab
if [ ! -f $dict/graphemes ];then
python /mnt/matylda6/baskar/espnet/src/utils/text2token.py $words > $dict/graphemes
fi
if [ ! -f $dict/lexicon.txt ]; then
sed "s| \+| |g;s| |\n|g" $dict/graphemes | sort | uniq  | grep -v "#" > $dict/nonsilence_phones.txt
paste $words $dict/graphemes | sort | uniq  | grep -v "#" > $dict/lexicon.txt
echo "<unk>    SIL" >> $dict/lexicon.txt
sed -i '/^$/d' $dict/lexicon.txt
sed -i '/^ \+$/d' $dict/lexicon.txt
fi 

if [ ! -f  $dict/nonsilence_phones.txt ]; then
touch $dict/extra_question.txt
sed "s| \+| |g;s| |\n|g" $dict/graphemes | sort | uniq  | grep -v "#" > $dict/nonsilence_phones.txt
sed -i '/^$/d' $dict/nonsilence_phones.txt
sed -i '/^\s\+$/d' $dict/nonsilence_phones.txt
echo "SIL" > $dict/silence_phones.txt
echo "SIL" > $dict/optional_silence.txt
fi

if [ ! -f $lang/words.txt ]; then
utils/prepare_lang.sh $dict '<unk>' $lang/local $lang
fi

if [ ! -f ${lm}.main/lm.gz ]; then
local/train_lms_srilm.sh --words-file $words --dev-text $tr_text \
 --train-text $lm_text $dict ${lm}.main
fi

if [ ! -f ${lm}/lm.gz ]; then
local/train_lms_srilm.sh --words-file $words --dev-text $tr_text \
 --train-text $mult_text $dict $lm
fi

if [ ! -f $lm/mixed.lm.gz ]; then
ngram -order 3 -vocab $words -unk -map-unk "<unk>" -lm ${lm}.main/lm.gz -mix-lm $lm/lm.gz -lambda 0.5 \
    -write-lm $lm/mixed.lm.gz
fi
if [ ! -f $lang_test/G.fst ]; then
# prepare new dictionary with all vocab
local/arpa2G.sh $lm/mixed.lm.gz $lang $lang_test
cp -r $lang/* $lang_test/
fi

