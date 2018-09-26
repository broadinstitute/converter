#!/bin/bash
source="/Users/rkothadi/Documents/Code/MyGithub/tarcreater/"
inputType="cdap"
targetType="gct"
inputFile=$source"input-data/cdap_proteome_tmt10.tsv"
targetFile=$source"output-data/cdap_target_proteome.gct"
dataType="proteome"
exptDesign=$source"input-data/cdap_proteome_sample.txt"
coerce=false
R CMD BATCH --vanilla "--args --inputfile $inputFile --inputtype $inputType --targettype $targetType --targetfile $targetFile --datatype $dataType --exptdesign $exptDesign --coerce $coerce" cdap.R

inputType="cdap"
targetType="gct"
exptDesign=$source"input-data/cdap_phosphoproteome_sample.txt"
inputFile=$source"input-data/cdap_phosphoproteome_tmt10_wo_rdesc.tsv"
dataType="phosphoproteome"
targetFile=$source"output-data/target_phosphoproteome.gct"
coerce=false
#R CMD BATCH --vanilla "--args --inputfile $inputFile --inputtype $inputType --targettype $targetType     --targetfile $targetFile --datatype $dataType --exptdesign $exptDesign --coerce $coerce" cdap.R

inputType="cdap"
targetType="gct"
inputFile=$source"input-data/cdap_phosphoproteome_tmt10_wo_rdesc.tsv"
dataType="phosphoproteome"
targetFile=$source"output-data/target_phosphoproteome.gct"
coerce=false
#R CMD BATCH --vanilla "--args --inputfile $inputFile --inputtype $inputType --targettype $targetType --targetfile $targetFile --datatype $dataType --coerce $coerce" cdap.R
