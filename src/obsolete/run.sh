#!/bin/bash
# Author: Ramani Kothadia
# Uncomment the desired R CMD BATCH command line to run your corresponding test

source="/Users/rkothadi/Documents/Code/MyGithub/tarcreater/"

## 1 : Proteome ( presence of exptdesign file will lead to gct 1.3 )
inputType="cdap"
targetType="gct"
inputFile=$source"input-data/cdap_proteome_tmt10.tsv"
targetFile=$source"output-data/cdap_target_proteome.gct"
dataType="proteome"
exptDesign=$source"input-data/cdap_proteome_sample.txt"
coerce=false
R CMD BATCH --vanilla "--args --inputfile $inputFile --inputtype $inputType --targettype $targetType --targetfile $targetFile --datatype $dataType --exptdesign $exptDesign --coerce $coerce" cdap.R


## 2: Phosphoproteome ( presence of exptdesign file will lead to gct 1.3 )
inputType="cdap"
targetType="gct"
exptDesign=$source"input-data/cdap_phosphoproteome_sample.txt"
inputFile=$source"input-data/cdap_phosphoproteome_tmt10_wo_rdesc.tsv"
dataType="phosphoproteome"
targetFile=$source"output-data/target_phosphoproteome.gct"
coerce=false
#R CMD BATCH --vanilla "--args --inputfile $inputFile --inputtype $inputType --targettype $targetType     --targetfile $targetFile --datatype $dataType --exptdesign $exptDesign --coerce $coerce" cdap.R


## 3 : Modified Proteome tmt file  w/o exptdesign ( will result in gct 1.2 )
## Note: Modified inputFile has no rdesc columns at the end. When you delete them for testing make sure you ( shift + delete ) in Excel which will result in '\t' deletions too, otherwise the result will be a gct 1.3 file with empty rdesc columns
inputType="cdap"
targetType="gct"
inputFile=$source"input-data/cdap_phosphoproteome_tmt10_wo_rdesc.tsv"
dataType="phosphoproteome"
targetFile=$source"output-data/target_phosphoproteome.gct"
coerce=false
#R CMD BATCH --vanilla "--args --inputfile $inputFile --inputtype $inputType --targettype $targetType --targetfile $targetFile --datatype $dataType --coerce $coerce" cdap.R
