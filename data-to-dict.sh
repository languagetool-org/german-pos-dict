#!/bin/bash
# Import MySQL dumps to local MySQL, export as CSV, transform CSV to Morfologik binary
# for use in e.g. LanguageTool

DBUSER="root"
DBPASS=""
LT_PATH="/prg/LanguageTool-3.6"
# the value of MySQL's secure_file_priv setting - only SQL files in here can be imported:
IMPORT_DIR=/var/lib/mysql-files

if [ ! -d $LT_PATH ]
then
  echo "Error: LT_PATH does not exist: $LT_PATH"
  exit
fi

if [ ! -d $IMPORT_DIR ]
then
  echo "Error: IMPORT_DIR does not exist: $IMPORT_DIRH"
  exit
fi

gunzip verben.sql.gz nomen.sql.gz adjektive.sql.gz

mysqladmin -u $DBUSER --password=$DBPASS create flexiontmp || { echo "Stopping due to previous error"; exit; }
echo "Starting MySQL import..."
mysql -u $DBUSER --password=$DBPASS flexiontmp <verben.sql
mysql -u $DBUSER --password=$DBPASS flexiontmp <nomen.sql
mysql -u $DBUSER --password=$DBPASS flexiontmp <adjektive.sql

function dbimport {
  echo "Running SQL to export data to CSV:"
  cat $IMPORT_DIR/tmp.sql
  echo "Running: mysql -u $DBUSER --password=$DBPASS flexiontmp <$IMPORT_DIR/tmp.sql"
  mysql -u $DBUSER --password=$DBPASS flexiontmp <$IMPORT_DIR/tmp.sql
  rm $IMPORT_DIR/tmp.sql
}

rm -f $IMPORT_DIR/output-verben.csv $IMPORT_DIR/output-nomen.csv $IMPORT_DIR/output-adjektive.csv

cat csv.sql | sed "s@_OUTPUT_@$IMPORT_DIR\/output-verben.csv@" | sed 's/_TABLE_/verben/' >$IMPORT_DIR/tmp.sql
dbimport

cat csv.sql | sed "s@_OUTPUT_@$IMPORT_DIR\/output-nomen.csv@" | sed 's/_TABLE_/nomen/' >$IMPORT_DIR/tmp.sql
dbimport

cat csv.sql | sed "s@_OUTPUT_@$IMPORT_DIR\/output-adjektive.csv@" | sed 's/_TABLE_/adjektive/' >$IMPORT_DIR/tmp.sql
dbimport

# ^\t -> some items have empty forms (because they are deleted), filter them:
grep -v -P '^\t' $IMPORT_DIR/output-verben.csv | python3 ./transform-pos.py >/tmp/output-verben-reordered.csv

cat src/main/resources/org/languagetool/resource/de/EIG.txt src/main/resources/org/languagetool/resource/de/sonstige.txt \
  /tmp/output-verben-reordered.csv $IMPORT_DIR/output-nomen.csv $IMPORT_DIR/output-adjektive.csv | grep -v -P '^\t' >output-all.csv
  
echo "Size of dictionary as plain text:"
ls -lh output-all.csv

echo "Building POS dictionary, using src/main/resources/org/languagetool/resource/de/german.info:"
java -cp $LT_PATH/languagetool.jar org.languagetool.tools.POSDictionaryBuilder -i output-all.csv -info src/main/resources/org/languagetool/resource/de/german.info -o src/main/resources/org/languagetool/resource/de/german.dict

echo "Building synth dictionary, using src/main/resources/org/languagetool/resource/de/german_synth.info:"
java -cp $LT_PATH/languagetool.jar org.languagetool.tools.SynthDictionaryBuilder -i output-all.csv -info src/main/resources/org/languagetool/resource/de/german_synth.info -o src/main/resources/org/languagetool/resource/de/german_synth.dict

LANG=C awk 'BEGIN {FS="\t"} {print $3}' output-all.csv | sort | uniq >src/main/resources/org/languagetool/resource/de/german_tags.txt

echo "Cleaning up temp files..."
rm output-all.csv $IMPORT_DIR/output-verben.csv $IMPORT_DIR/output-verben-reordered.csv $IMPORT_DIR/output-nomen.csv $IMPORT_DIR/output-adjektive.csv

echo "Dropping temp database..."
mysqladmin -u $DBUSER --password=$DBPASS drop flexiontmp
