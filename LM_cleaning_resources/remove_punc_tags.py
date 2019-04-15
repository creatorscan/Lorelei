import sys
import codecs
import argparse

def load_utf8(trans_file):
    output = codecs.open(trans_file, 'r', encoding='utf-8')
    return output

def load_ascii(trans_file):
    output = codecs.open(trans_file, 'r', encoding='ascii')
    return output


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Remove punct and unknown symbols')
    parser.add_argument('wordsfile', help='file with the actual words')
    parser.add_argument('tagsfile', help='file with tags for words in wordsfile')
    parser.add_argument('outputfile', help='Output file with removed punct tags ')

    args = parser.parse_args()

    words = load_utf8(args.wordsfile)
    tags = load_ascii(args.tagsfile)

    print("loop started")

with codecs.open(args.outputfile, 'w', encoding='utf-8') as out_file:
    l=0
    for line1, line2 in zip(words, tags):
        wordTokens = line1.split(' ')
        tagTokens = line2.split(' ')
        #print("Reading line",l, " with len", len(wordTokens), len(tagTokens))
        for i in range(0, len(wordTokens)):
            if tagTokens[i] == 'punct':
                wordTokens[i] = '<eps>'
            if tagTokens[i] == 'punct\n':
                wordTokens[i] = '<eps>\n'
            if tagTokens[i] == 'unknown':
                wordTokens[i] = '<unkn>'
            if tagTokens[i] == 'unknown\n':
                wordTokens[i] = '<unkn>\n'
            if tagTokens[i] == 'url':
                wordTokens[i] = '<eps>'
            if tagTokens[i] == 'url\n':
                wordTokens[i] = '<eps>\n'
            if tagTokens[i] == 'tag':
                wordTokens[i] = '<eps>'
            if tagTokens[i] == 'tag\n':
                wordTokens[i] = '<eps>\n'
        l+=1
        out_file.write(" ".join(wordTokens))
    print("loop ended")
