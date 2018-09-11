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
  if (args[['-f']] == "gct" && args[['-v']] == "1.2" && !("-e" %in% names(args))){
    stop("### Error: '-e' Option Required With '-f' : \"gct\" and '-v' : 1.2.\n", call. = TRUE)
  }
}

extract_expt_desn <- function(myfile){
  return(read.csv(myfile, header = TRUE, sep = ','))
}

reorder <- function(expfile, expdata, gctcids){
  rofile <- "exptdesign_ro.csv"
  rodata <- data.frame()
  ordids <- c()
  for (sample in gctcids){
    oldidx <- which(expdata$Sample.ID == sample)
    ordids <- c(ordids, oldidx)
  }
  ordids <- c(ordids, setdiff(1:nrow(expdata), ordids))
  rodata <- rbind(rodata, expdata[ordids, ])
  rownames(rodata) <- NULL
  write.csv(rodata, rofile, quote = FALSE, row.names = FALSE)
  system(paste0("mv ", expfile, " ", "exptdesign_orig.csv"))
  system(paste0("mv ", rofile, " ", expfile))
}

check_gct_against_expt <- function(myfile){
  if (!("-e" %in% names(args))) return()
  gctdata <- suppressMessages(parse.gctx(myfile))
  if (args[['-v']] != strsplit(gctdata@version, "[#]")[[1]][-1]){
    stop("### Error: Version Entered and .GCT file don't match.\n", call. = TRUE)
  }
  gctcids <- gctdata@cid
  expdata <- extract_expt_desn(args[['-e']])
  if (nrow(expdata) < length(gctcids)){
    stop("### Error: Samples in .GCT not found in Experiment Design file.\n", call. = TRUE)
  } else if (nrow(expdata) > length(gctcids)){
    print(paste0("### Warning: Some Samples Missing in ", myfile, " file."))
  }
  expsampl <- expdata[['Sample.ID']][1:nrow(expdata)]
  freorder <- FALSE
  for (index in length(gctcids)){
    if (!(gctcids[index] %in% expsampl)){
      stop("### Error: Sample Mismatch between Experiment Design and .GCT file. (Sample not found in Experiment Design.\n)", call. = TRUE)
    } else if (gctcids[index] != expsampl[index]) freorder <- TRUE
  }
  if (freorder) reorder(args[['-e']], expdata, gctcids)
}

stub <- function(myfile){
  
}

check_format <- function(myfile){
  ext <- tail(strsplit(myfile, "[.]")[[1]], 1)
  opt <- list("gct"=check_gct_against_expt, "cct"=stub)
  opt[[ext]](myfile)
}

create_tar <- function(){
  tardir  <- strsplit(args[['-o']], "[.]")[[1]][1]
  system(paste0("mkdir -p ", tardir))
  system(paste0("mkdir -p ", tardir, "/data"))
  system(paste0("mkdir -p ", tardir, "/parsed-data"))
  system(paste0("cp ", args[["-e"]], " ", tardir, "/data/."))
  system(paste0("cp ", args[["-p"]], " ", tardir, "/parsed-data/."))
  system(paste0("cp exptdesign_orig.csv ", tardir, "/data/."))
  if ("-m" %in% names(args)){
    for (extra in args[["-m"]]){
      system(paste0("cp ", extra, " ", tardir, "/parsed-data/."))
    }
  }
  system(paste0("tar -cvf ", args[['-o']], " ", tardir), ignore.stderr = TRUE)
  system(paste0("rm -rf ", tardir))
}

main <- function(){
  system(paste0("cd ", args[['-s']]))
  set_arguments()
  check_format(args[["-p"]])
  create_tar()
}

if (!interactive()){
  main()
}