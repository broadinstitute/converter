#!/usr/bin/env Rscript
args <- list()

set_arguments <- function() {
  sysargs <- commandArgs(trailingOnly = TRUE)
  sysalen <- length(sysargs)
  valid   <- c('-p', '-e', '-o', '-m')
  index   <- 1
  while (index <= sysalen && sysargs[index] != '-m'){
    option <- sysargs[index]
    if (option %in% valid){
      args[[option]] <- sysargs[index+1]
      index <- index + 2
    } else if (!(option %in% valid)){
      stop("# Error: Invalid Option.\n", call. = TRUE)
    }
  }
  index <- index + 1
  while (index <= sysalen){
    args[["-m"]] <- c(args[["-m"]], sysargs[index])
    index <- index + 1
  }
  if (!("-p" %in% valid) || !("o" %in% valid)){
    stop("# Error: -p/-o required.\n", call. = TRUE)
  }
}

check_gct_against_expt <- function(myfile){
  
}

stub <- function(myfile){
  
}

check_format <- function(myfile){
  ext <- strsplit(myfile, "[.]")[[1]][-1]
  opt <- list("gct"=check_gct_against_expt, "cct"=stub)
  opt[[ext]](myfile)
}
set_arguments()

