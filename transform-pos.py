#!/usr/bin/python3
# coding=utf-8
# Re-order POS tags, as the VER tags coming from korrekturen.de
# have a slightly different order than what LanguageTool expects

import fileinput
import re
import sys

ignored = 0
silentlyIgnored = 0
for line in fileinput.input():
    if re.match(".*\t(VER|PA1|PA2):.*", line):
        reformatted = re.sub(r"VER:(PLU|SIN):(SFT|NON):([123]):(KJ[12]|PRT|PRÄ):(NEB)?", r"VER:\3:\1:\4:\2:\5", line)
        reformatted = re.sub(r"VER:(PLU|SIN):(SFT|NON):([123]):(KJ[12]|PRT|PRÄ)", r"VER:\3:\1:\4:\2", reformatted)
        reformatted = re.sub(r"VER:(SIN|PLU):IMP:(SFT|NON)", r"VER:IMP:\1:\2", reformatted)
        reformatted = re.sub(r"VER:(SIN|PLU):IMP", r"VER:IMP:\1", reformatted)
        reformatted = re.sub(r"(PA[12]):(NOM|DAT|GEN|AKK):(SIN|PLU):(MAS|FEM|NEU):(DEF|IND|SOL):(VER):(GRU|KOM|SUP)", r"\1:\2:\3:\4:\7:\5:\6", reformatted)
        reformatted = re.sub(r"(PA[12]):(NOM|DAT|GEN|AKK):(SIN|PLU):(MAS|FEM|NEU):(DEF|IND|SOL):(GRU|KOM|SUP)", r"\1:\2:\3:\4:\6:\5", reformatted)
        reformatted = re.sub(r"(PA[12]):(VER):(GRU|KOM|SUP):(PRD)", r"\1:\4:\3:\2", reformatted)
        reformatted = re.sub(r"(PA[12]):(GRU|KOM|SUP):(PRD)", r"\1:\3:\2", reformatted)
        reformatted = re.sub(r"VER:(MOD|AUX):(SIN|PLU):IMP", r"VER:\1:IMP:\2", reformatted)
        reformatted = re.sub(r"VER:(MOD|AUX):(SIN|PLU):([123]):(PRÄ|PRT|KJ[12])", r"VER:\1:\3:\2:\4", reformatted)
        reformatted = re.sub(r"VER:(SIN|PLU):IMP", r"VER:IMP:\1", reformatted)
        if reformatted == line and \
                not re.match(r".*VER:(INF|PA[12]):(SFT|NON)", line) and \
                not re.match(r".*VER:EIZ:(NON|SFT)", line) and \
                not re.match(r".*VER:(MOD|AUX):(INF|PA1|PA2)", line) and \
                not re.match(r".*VER:PA[12]", line):
            ignored += 1
            sys.stderr.write("Ignored (not changed): " + line.strip() + "\n")
        else:
            print(reformatted.strip())
    else:
        if not re.search(r"\?", line):
            ignored += 1
            sys.stderr.write("Ignored (not matched): " + line.strip() + "\n")
        else:
            silentlyIgnored += 1

sys.stderr.write("Ignored: " + str(ignored) + "\n")
sys.stderr.write("Silently ignored: " + str(silentlyIgnored) + "\n")
