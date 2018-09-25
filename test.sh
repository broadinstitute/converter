R CMD BATCH --vanilla "--args -p /Users/rkothadi/Documents/Code/MyGithub/tarcreater/input-data/UCEC_CNA_gene_level_hg19_V1.cct -e /Users/rkothadi/Documents/Code/MyGithub/tarcreater/input-data/UCEC_clinical_genotype_phenotype_V1.1.tsi.xlsx -o parseInput.tar -f cct -dt proteome -rna /Users/rkothadi/Documents/Code/MyGithub/tarcreater/input-data/microarray-data.gct -cna /Users/rkothadi/Documents/Code/MyGithub/tarcreater/input-data/medullo-cna-data.gct -c T -log 2" src/tarcreater.r

R CMD BATCH --vanilla "--args -p /Users/rkothadi/Documents/Code/MyGithub/tarcreater/input-data/UCEC_phosphoproteomics_gene_level_V1.cct -e /Users/rkothadi/Documents/Code/MyGithub/tarcreater/input-data/UCEC_clinical_genotype_phenotype_V1.1.tsi.xlsx -o parseInput.tar -f cct -dt phosphoproteome -rna /Users/rkothadi/Documents/Code/MyGithub/tarcreater/input-data/microarray-data.gct -cna /Users/rkothadi/Documents/Code/MyGithub/tarcreater/input-data/medullo-cna-data.gct -c T -log 2 -t T" src/tarcreater.r

R CMD BATCH --vanilla "--args -p /Users/rkothadi/Documents/Code/MyGithub/tarcreater/input-data/UCEC_phosphoproteomics_site_level_V1.cct -e /Users/rkothadi/Documents/Code/MyGithub/tarcreater/input-data/UCEC_clinical_genotype_phenotype_V1.1.tsi.xlsx -o parseInput.tar -f cct -dt phosphoproteome -rna /Users/rkothadi/Documents/Code/MyGithub/tarcreater/input-data/microarray-data.gct -cna /Users/rkothadi/Documents/Code/MyGithub/tarcreater/input-data/medullo-cna-data.gct -c T -log 2 -t T" src/tarcreater.r

R CMD BATCH --vanilla "--args -p /Users/rkothadi/Documents/Code/MyGithub/tarcreater/input-data/UCEC_phosphoproteomics_site_level_V1.cct -o parseInput.tar -f cct -dt phosphoproteome -rna /Users/rkothadi/Documents/Code/MyGithub/tarcreater/input-data/microarray-data.gct -cna /Users/rkothadi/Documents/Code/MyGithub/tarcreater/input-data/medullo-cna-data.gct -log 2" src/tarcreater.r

R CMD BATCH --vanilla "--args -p /Users/rkothadi/Documents/Code/MyGithub/tarcreater/input-data/microarray-data.gct -e /Users/rkothadi/Documents/Code/MyGithub/tarcreater/input-data/exptdesign.csv -o parseInput.tar -f gct -dt proteome -rna /Users/rkothadi/Documents/Code/MyGithub/tarcreater/input-data/microarray-data.gct -cna /Users/rkothadi/Documents/Code/MyGithub/tarcreater/input-data/medullo-cna-data.gct -c T -log 2 -v 1.2" src/tarcreater.r

R CMD BATCH --vanilla "--args -p /Users/rkothadi/Documents/Code/MyGithub/tarcreater/input-data/proteome-ratio.gct -e /Users/rkothadi/Documents/Code/MyGithub/tarcreater/input-data/exptdesign.csv -o parseInput.tar -f gct -dt proteome -rna /Users/rkothadi/Documents/Code/MyGithub/tarcreater/input-data/microarray-data.gct -cna /Users/rkothadi/Documents/Code/MyGithub/tarcreater/input-data/medullo-cna-data.gct -log 2 -v 1.3" src/tarcreater.r