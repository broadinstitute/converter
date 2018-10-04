#!/bin/bash
# Author: Ramani Kothadia
# Uncomment the desired R CMD BATCH command line to run your corresponding test

source="/Users/rkothadi/Documents/Code/MyGithub/tarcreater/"

## 1 : Proteome ( presence of exptdesign file will lead to gct 1.3 )
inputType="cdap"
targetType="gct"
inputFile=$source"input-data/cdap_proteome_tmt10.tsv"
targetFile=$source"output-test-data/cdap_target_proteome.gct"
dataType="proteome"
exptDesign=$source"input-data/cdap_proteome_sample.txt"
#R CMD BATCH --vanilla "--args --inputfile $inputFile --inputtype $inputType --targettype $targetType --targetfile $targetFile --datatype $dataType --exptdesign $exptDesign" converter.R


## 2: Phosphoproteome ( presence of exptdesign file will lead to gct 1.3 )
inputType="cdap"
targetType="gct"
exptDesign=$source"input-data/cdap_phosphoproteome_sample.txt"
inputFile=$source"input-data/cdap_phosphoproteome_tmt10_wo_rdesc.tsv"
dataType="phosphoproteome"
targetFile=$source"output-test-data/target_phosphoproteome.gct"
R CMD BATCH --vanilla "--args --inputfile $inputFile --inputtype $inputType --targettype $targetType --targetfile $targetFile --datatype $dataType --exptdesign $exptDesign" converter.R


## 3 : Modified Proteome tmt file  w/o exptdesign ( will result in gct 1.2 )
## Note: Modified inputFile has no rdesc columns at the end. When you delete them for testing make sure you ( shift + delete ) in Excel which will result in '\t' deletions too, otherwise the result will be a gct 1.3 file with empty rdesc columns
inputType="cdap"
targetType="gct"
inputFile=$source"input-data/cdap_phosphoproteome_tmt10_wo_rdesc.tsv"
dataType="phosphoproteome"
targetFile=$source"output-test-data/target_phosphoproteome_v2.gct"
R CMD BATCH --vanilla "--args --inputfile $inputFile --inputtype $inputType --targettype $targetType --targetfile $targetFile --datatype $dataType" converter.R

## 4: Phosphoproteome-Gene-Level ( presence of exptdesign will lead to gct 1.3 )
inputType="cct"
targetType="gct"
inputFile=$source"input-data/UCEC_phosphoproteomics_gene_level_V1.cct"
exptDesign=$source"input-data/UCEC_clinical_genotype_phenotype_V1.1.tsi.xlsx"
dataType="phosphoproteome"
targetFile=$source"output-test-data/cct_target_phosphoproteome.gct"
R CMD BATCH --vanilla "--args --inputfile $inputFile --inputtype $inputType --targettype $targetType --targetfile $targetFile --datatype $dataType --exptdesign $exptDesign --coerce -t" converter.R

## 5: Phosphoproteome-Site-Level ( presence of exptdesign will lead to gct 1.3 )
inputType="cct"
targetType="gct"
inputFile=$source"input-data/UCEC_phosphoproteomics_site_level_V1.cct"
exptDesign=$source"input-data/UCEC_clinical_genotype_phenotype_V1.1.tsi.xlsx"
dataType="phosphoproteome"
targetFile=$source"output-test-data/cct_target_phosphoproteome_site.gct"
R CMD BATCH --vanilla "--args --inputfile $inputFile --inputtype $inputType --targettype $targetType --targetfile $targetFile --datatype $dataType --exptdesign $exptDesign --coerce -t" converter.R

## 6: Proteome ( presence of exptdesign will lead to gct 1.3 )
inputType="cct"
targetType="gct"
inputFile=$source"input-data/UCEC_CNA_gene_level_hg19_V1.cct"
exptDesign=$source"input-data/UCEC_clinical_genotype_phenotype_V1.1.tsi.xlsx"
dataType="proteome"
targetFile=$source"output-test-data/cct_target_proteome.gct"
R CMD BATCH --vanilla "--args --inputfile $inputFile --inputtype $inputType --targettype $targetType --targetfile $targetFile --datatype $dataType --exptdesign $exptDesign --coerce" converter.R

## 7: Proteome w/o exptDesign File : gct v2
inputType="cct"
targetType="gct"
inputFile=$source"input-data/UCEC_CNA_gene_level_hg19_V1.cct"
dataType="proteome"
targetFile=$source"output-test-data/cct_target_proteome_v2.gct"
R CMD BATCH --vanilla "--args --inputfile $inputFile --inputtype $inputType --targettype $targetType --targetfile $targetFile --datatype $dataType --coerce" converter.R

