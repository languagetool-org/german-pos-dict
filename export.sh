#!/bin/sh
# export binary Morfologik file to plain text

LT_PATH="/prg/LanguageTool-3.5-SNAPSHOT"

java -cp $LT_PATH/languagetool.jar org.languagetool.tools.DictionaryExporter -i src/main/resources/org/languagetool/resource/de/german.dict -info src/main/resources/org/languagetool/resource/de/german.info -o dictionary.dump
echo "Result written to dictionary.dump"
