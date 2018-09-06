FROM broadcptac/pgdac_main:1
MAINTAINER Ramani Kothadia (rkothadi@broadinstitute.org)
RUN apt-get update
RUN apt-get install -y python
RUN apt-get install -y python-pip
RUN pip install cmapPy

RUN mkdir /prot/proteomics/Projects/PGDAC/src/tarcreater
ADD tarcreater/execute_job.py /prot/proteomics/Projects/PGDAC/src/tarcreater/
ADD tarcreater/tarcreater.py /prot/proteomics/Projects/PGDAC/src/tarcreater/


