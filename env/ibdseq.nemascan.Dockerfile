FROM continuumio/miniconda
MAINTAINER Katie Evans <kathryn.evans@northwestern.edu>

COPY ibdseq.nemascan.yml .
RUN \
   conda env update -n root -f ibdseq.nemascan.yml \
&& conda clean -a