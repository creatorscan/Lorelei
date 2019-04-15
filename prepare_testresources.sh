#!/bin/bash

set -e

main=$PWD
tag=IL9

. utils/parse_options.sh

if [ $# != 2 ]; then
  echo "Usage: "
  echo "  $0 [options] <src_dict> <tgt_data>"
  echo "e.g.:"
  echo " $0 --main=PWD --tag=IL9 data/local/dict data/IL9"
  echo "Options"
  echo "   --main=pwd     # name for main dir"
  echo "   --tag=<il9>     # xvector dir"
  exit 1;
fi

uroman=/mnt/matylda6/baskar/uroman/bin
dict_src=$1
tgt_data=$2

stage=2
data=$main/data
dict=`echo $dict_src | sed "s|/$||g"`
dict=${dict}_${tag}

mkdir -p $dict
# copy default files from train dictionary
if [ $stage -le 1 ]; then
cp $dict_src/{extra_questions.txt,nonsilence_phones.txt,optional_silence.txt,silence_phones.txt} $dict/
cut -f2- -d " " $tgt_data/text | sed "s|<[a-z]\+>||g;s|<v-noise>||g" | sed "s| |\n|g" > $dict/words
sed -i '/^	\+$/d' $dict/words
sed -i '/^$/d' $dict/words
sed -i '/^ \+$/d' $dict/words
sed -i "s|[-,_]||g;s|\.||g;s|:||g;s|^ ||g;s|  \+| |g;s| $||g" $dict/words
sed -i "s|\'||g" $dict/words
fi

cp $dict/words $dict/words.tmp
cat $dict/words.tmp | sort -u > $dict/words
perl $uroman/uroman.pl < $dict/words > $dict/prons.tmp
bash local/punctuations.sh $dict/prons.tmp
awk '{print tolower($0)}' $dict/prons.tmp > $dict/prons
sed -i "s|[',-,_]||g;s|.| & |g;s|\.||g;s|:||g;s|^ ||g;s|  \+| |g;s| $||g" $dict/prons
paste $dict/words $dict/prons | sort -u | sed '/	$/d' > $dict/lexicon.tmp
grep "<" $dict_src/lexicon.txt >> $dict/lexicon.tmp
cp $dict/lexicon.tmp $dict/lexicon.txt

utils/prepare_lang.sh $dict "<unk>" $data/local/lang_${tag} $data/lang_${tag}
local/train_lms_srilm.sh --words-file $data/lang_${tag}/words.txt --train-text $tgt_data/text \
  --oov-symbol "<unk>" $tgt_data $data/srilm_${tag}

# prune if LM size is not less than 30 MB
# ngram -lm mixed.lm -prune 1e-8 -write-lm mixed_pruned.lm
local/arpa2G.sh $data/srilm_${tag}/lm.gz $data/lang_${tag} $data/lang_${tag}
