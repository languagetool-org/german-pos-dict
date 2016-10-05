#!/bin/bash
# Import MySQL dumps to local MySQL, export as CSV, transform CSV to Morfologik binary
# for use in e.g. LanguageTool

DBUSER="root"
DBPASS=""
LT_PATH="/prg/LanguageTool-3.5-SNAPSHOT"

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

cat /tmp/output-verben.csv /tmp/output-nomen.csv /tmp/output-adjektive.csv >output-all.csv

echo "Size of dictionary as plain text:"
ls -lh output-all.csv

echo "Building POS dictionary:"
java -cp $LT_PATH/languagetool.jar org.languagetool.tools.POSDictionaryBuilder -i output-all.csv -info $LT_PATH/org/languagetool/resource/de/german.info -o src/main/resources/org/languagetool/resource/de/german.dict
cp $LT_PATH/org/languagetool/resource/de/german.info src/main/resources/org/languagetool/resource/de/

echo "Building synth dictionary:"
java -cp $LT_PATH/languagetool.jar org.languagetool.tools.SynthDictionaryBuilder -i output-all.csv -info $LT_PATH/org/languagetool/resource/de/german_synth.info -o src/main/resources/org/languagetool/resource/de/german_synth.dict
cp $LT_PATH/org/languagetool/resource/de/german_synth.info src/main/resources/org/languagetool/resource/de/

echo "Cleaning up temp files..."
rm output-all.csv

echo "Dropping temp database..."
mysqladmin -u $DBUSER --password=$DBPASS drop flexiontmp
