#!/usr/bin/env Rscript

if(!require("pacman")) install.packages("pacman")
pacman::p_load_gh("cmap/cmapR")

args <- list()

set_arguments <- function() {
  sysargs <- commandArgs(trailingOnly = TRUE)
  sysalen <- length(sysargs)
  valid   <- c('-p', '-e', '-o', '-m')
  index   <- 1
  while (index <= sysalen && sysargs[index] != '-m'){
    option <- sysargs[index]
    if (option %in% valid){
      args[[option]] <<- sysargs[index+1]
      index <- index + 2
    } else if (!(option %in% valid)){
      stop("# Error: Invalid Option.\n", call. = TRUE)
    }
  }
  index <- index + 1
  while (index <= sysalen){
    args[["-m"]] <<- c(args[["-m"]], sysargs[index])
    index <- index + 1
  }
  if (!("-p" %in% names(args)) || !("-o" %in% names(args))){
    stop("# Error: -p/-o required.\n", call. = TRUE)
  }
}

extract_expt_desn <- function(){
  return(read.csv(args[["-e"]], header = TRUE, sep = ','))
}

check_gct_against_expt <- function(myfile){
  out <- parse.gctx(myfile)
  if (out@version == "#1.2"){
    if (!("-e" %in% args)){
      stop("# Error: -e option required for .GCT (1.2).\n", call. = TRUE)
    }
  }
  gctcid <- out@cid
  expcsv <- extract_expt_desn()
  if (nrow(expcsv) < length(gctcid)){
    stop("# Error: Samles in .GCT not found in EXPT DESN file.\n", call. = TRUE)
  } else if (nrow(expcsv) > length(gctcid)){
    print(paste0("# Warning: Some Samples Missing in ", myfile, " file."))
  } else {
    print("# Success: Check OK.\n")
  }
}

stub <- function(myfile){
  
}

check_format <- function(myfile){
  ext <- strsplit(myfile, "[.]")[[1]][-1]
  opt <- list("gct"=check_gct_against_expt, "cct"=stub)
  opt[[ext]](myfile)
}

create_tar <- function(){
  option <- strsplit(args[["-o"]], "[/]")[[1]]
  mydirs <- head(option[-1], -1)
  anadir <- ""
  for (dir in mydirs){
    anadir <- file.path(anadir, dir)
  }
  tardir <- file.path(anadir, strsplit(tail(option, 1), "[.]")[[1]][1])
  system(paste0("mkdir -p ", tardir))
  system(paste0("mkdir -p ", tardir, "/data"))
  system(paste0("mkdir -p ", tardir, "/parsed-data"))
  system(paste0("cp ", args[["-e"]], " ", tardir, "/data/."))
  system(paste0("cp ", args[["-p"]], " ", tardir, "/parsed-data/."))
  if ("-m" %in% names(args)){
    for (extra in args[["-m"]]){
      system(paste0("cp ", extra, " ", tardir, "/parsed-data/."))
    }
  }
  system(paste0("tar -cvf ", args[["-o"]], " ", tardir))
  system(paste0("rm -rf ", tardir))
}

set_arguments()
check_format(args[["-p"]])
create_tar()

