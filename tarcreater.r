#!/usr/bin/env Rscript

if(!suppressMessages(require("pacman"))) install.packages("pacman")
pacman::p_load_gh("cmap/cmapR")

args <- list()

set_arguments <- function() {
  sysargs <- commandArgs(trailingOnly = TRUE)
  sysalen <- length(sysargs)
  valid   <- c('-p', '-e', '-o', '-m', '-v', '-n', '-f', '-s')
  index   <- 1
  while (index <= sysalen && sysargs[index] != '-m'){
    option <- sysargs[index]
    if (option %in% valid){
      args[[option]] <<- sysargs[index+1]
      index <- index + 2
    } else if (!(option %in% valid)){
      stop("### Error: Invalid Option.\n", call. = TRUE)
    }
  }
  index <- index + 1
  while (index <= sysalen){
    args[["-m"]] <<- c(args[["-m"]], sysargs[index])
    index <- index + 1
  }
  if (!("-p" %in% names(args)) || !("-o" %in% names(args)) ||
      !("-f" %in% names(args)) || !("-s" %in% names(args))){
    stop("### Error: '-p'/'-o'/'-f'/'-s' Options Required.\n", call. = TRUE)
  }
  if (args[['-f']] == "gct" && !('-v' %in% names(args))){
    stop("### Error: '-v' Option Required With '-f' : \"gct\".\n", call. = TRUE)
  }
  if (args[['-f']] == "gct" && as.numeric(args[['-v']]) == 1.2 && !("-e" %in% names(args))){
    stop("### Error: '-e' Option Required With '-f' : \"gct\" and '-v' : 1.2.\n", call. = TRUE)
  }
}

extract_expt_desn <- function(){
  return(read.csv(args[["-e"]], header = TRUE, sep = ','))
}

check_gct_against_expt <- function(myfile){
  out <- suppressMessages(parse.gctx(myfile))
  if (out@version == "#1.2"){
    if (!("-e" %in% args)){
      stop("### Error: -e option required for .GCT (1.2).\n", call. = TRUE)
    }
  }
  gctcid <- out@cid
  expcsv <- extract_expt_desn()
  if (nrow(expcsv) < length(gctcid)){
    stop("### Error: Samples in .GCT not found in Experiment Design file.\n", call. = TRUE)
  } else if (nrow(expcsv) > length(gctcid)){
    print(paste0("=== Warning: Some Samples Missing in ", myfile, " file."))
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
  tardir  <- strsplit(args[['-o']], "[.]")[[1]][1]
  system(paste0("cd ", args[['-s']]))
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
  system(paste0("tar -cvf ", args[['-o']], " ", tardir), ignore.stderr = TRUE)
  system(paste0("rm -rf ", tardir))
}

set_arguments()
check_format(args[["-p"]])
create_tar()
