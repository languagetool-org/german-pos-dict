#!/bin/bash
# export binary Morfologik file to plain text

LT_PATH="/prg/LanguageTool-4.5"

if [ ! -d "$LT_PATH" ]; then
  echo "Error: LT_PATH does not exist or is not a directory: '$LT_PATH' - set it here in the script"
  exit
fi
if [ ! -f "$LT_PATH/languagetool.jar" ]; then
  echo "Error: LT_PATH does not contain 'languagetool.jar': '$LT_PATH' - set it here in the script to a directory that contains LanguageTool desktop/stand-alone edition"
  exit
fi

java -cp $LT_PATH/languagetool.jar org.languagetool.tools.DictionaryExporter -i src/main/resources/org/languagetool/resource/de/german.dict -info src/main/resources/org/languagetool/resource/de/german.info -o dictionary.dump
echo "Result written to dictionary.dump"
