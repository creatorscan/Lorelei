# Note: this code is only for Russian and removes other language unicode
#characters
#\u2e80-\u2eff - Chinese japanese Korean (CJK) radicals
#\u2f00-\u2fdf - Kangxi radicals
#\u3000-\u303f - CJK symbols and punctuations
#\u31c0-\u31ef - CJK strokes
#\u31c0-\u31ef - CJK strokes
#\u3200-\u32ff - CJK letters and months
#\u3300-\u33ff - CJK compatibility
#\u3400-\u3fff - CJK unified ideographs ext. A
#\u4000-\u4dbf - CJK unified ideographs ext. A
#\u4e00-\u4fff - CJK unified ideographs
# latin

#

import sys
import codecs
import argparse
import re


def load_utf8(trans_file):
    output = codecs.open(trans_file, 'r', encoding='utf-8')
    return output


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Remove hex codes')
    parser.add_argument('inputfile', help='text file with hexcodes and other formats')
    parser.add_argument('outputfile', help='hex codes removed output file')

    args = parser.parse_args()
    words = load_utf8(args.inputfile)

with codecs.open(args.outputfile, 'w', encoding='utf-8') as output:
    for line in words:
        wordTokens = line.split('  ')
        for i in range(0, len(wordTokens)):
            wordTokens = re.sub(r'[\x00-\x7f]', r' ', str(wordTokens))
            wordTokens = re.sub(r'[\xa0-\xaf]', r' ', str(wordTokens))
            wordTokens = re.sub(r'[\xb0-\xbf]', r' ', str(wordTokens))
            wordTokens = re.sub(r'[\u2000-\u206F]', r' ', str(wordTokens))
        wordTokens = re.sub(r'\s\s+', r' ', str(wordTokens))
        output.write("".join(wordTokens))
        output.write('\n')
    print("loop ended")
