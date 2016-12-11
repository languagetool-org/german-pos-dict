#!/bin/bash
# Import MySQL dumps to local MySQL, export as CSV, transform CSV to Morfologik binary
# for use in e.g. LanguageTool

DBUSER="root"
DBPASS=""
LT_PATH="/prg/LanguageTool-3.5"

gunzip verben.sql.gz nomen.sql.gz adjektive.sql.gz

mysqladmin -u $DBUSER --password=$DBPASS create flexiontmp || { echo "Stopping due to previous error"; exit; }
echo "Starting MySQL import..."
mysql -u $DBUSER --password=$DBPASS flexiontmp <verben.sql
mysql -u $DBUSER --password=$DBPASS flexiontmp <nomen.sql
mysql -u $DBUSER --password=$DBPASS flexiontmp <adjektive.sql

function dbimport {
  echo "Running SQL to export data to CSV:"
  cat tmp.sql
  mysql -u $DBUSER --password=$DBPASS flexiontmp <tmp.sql
  rm tmp.sql
}

rm -f /tmp/output-verben.csv /tmp/output-nomen.csv /tmp/output-adjektive.csv

cat csv.sql | sed 's/_OUTPUT_/\/tmp\/output-verben.csv/' | sed 's/_TABLE_/verben/' >tmp.sql
dbimport

cat csv.sql | sed 's/_OUTPUT_/\/tmp\/output-nomen.csv/' | sed 's/_TABLE_/nomen/' >tmp.sql
dbimport

cat csv.sql | sed 's/_OUTPUT_/\/tmp\/output-adjektive.csv/' | sed 's/_TABLE_/adjektive/' >tmp.sql
dbimport

# ^\t -> some items have empty forms (because they are deleted), filter them:
grep -v -P '^\t' /tmp/output-verben.csv | python3 ./transform-pos.py >/tmp/output-verben-reordered.csv

cat src/main/resources/org/languagetool/resource/de/EIG.txt src/main/resources/org/languagetool/resource/de/sonstige.txt \
  /tmp/output-verben-reordered.csv /tmp/output-nomen.csv /tmp/output-adjektive.csv | grep -v -P '^\t' >output-all.csv
  
echo "Size of dictionary as plain text:"
ls -lh output-all.csv

echo "Building POS dictionary, using src/main/resources/org/languagetool/resource/de/german.info:"
java -cp $LT_PATH/languagetool.jar org.languagetool.tools.POSDictionaryBuilder -i output-all.csv -info src/main/resources/org/languagetool/resource/de/german.info -o src/main/resources/org/languagetool/resource/de/german.dict

echo "Building synth dictionary, using src/main/resources/org/languagetool/resource/de/german_synth.info:"
java -cp $LT_PATH/languagetool.jar org.languagetool.tools.SynthDictionaryBuilder -i output-all.csv -info src/main/resources/org/languagetool/resource/de/german_synth.info -o src/main/resources/org/languagetool/resource/de/german_synth.dict

LANG=C awk 'BEGIN {FS="\t"} {print $3}' output-all.csv | sort | uniq >src/main/resources/org/languagetool/resource/de/german_tags.txt

echo "Cleaning up temp files..."
rm output-all.csv /tmp/output-verben.csv /tmp/output-verben-reordered.csv /tmp/output-nomen.csv /tmp/output-adjektive.csv

echo "Dropping temp database..."
mysqladmin -u $DBUSER --password=$DBPASS drop flexiontmp
