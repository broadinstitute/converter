FROM broadcptac/pgdac_main:1
MAINTAINER Ramani Kothadia (rkothadi@broadinstitute.org)
ADD tarcreater.r /prot/proteomics/Projects/PGDAC/src/

RUN R -e "install.packages('pacman'); library(pacman); p_load_gh('cmap/cmapR'); p_load(glue) "
