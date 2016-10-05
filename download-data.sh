#!/bin/bash
# Download inflection data from korrekturen.de (based on Morphy, thus https://creativecommons.org/licenses/by-sa/4.0/)

curl https://www.korrekturen.de/flexion/download/verben.sql.gz >verben.sql.gz
curl https://www.korrekturen.de/flexion/download/nomen.sql.gz >nomen.sql.gz
curl https://www.korrekturen.de/flexion/download/adjektive.sql.gz >adjektive.sql.gz
