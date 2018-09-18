if(!suppressMessages(require("pacman"))) install.packages("pacman")
p_load(cmapR)
p_load(openxlsx)
p_load(glue)
p_load(optparse)

args <- list()
freorder <- FALSE
srcdir <- ""
inpdir <- ""
pinp <- ""
einp <- ""

set_arguments <- function() {
  sysargs <- commandArgs(trailingOnly = TRUE)
  sysalen <- length(sysargs)
  valid   <- c('-p', '-e', '-o', '-m', '-v', '-n', '-f', '-t')
  index   <- 1
  while (index <= sysalen && sysargs[index] != '-m'){
    option <- sysargs[index]
    if (option %in% valid){
      args[[option]] <<- sysargs[index+1]
      index <- index + 2
    } else if (!(option %in% valid)){
      stop(glue("### Error: Invalid Option {option}.\n"), call. = TRUE)
    }
  }
  index <- index + 1
  while (index <= sysalen){
    args[["-m"]] <<- c(args[["-m"]], sysargs[index])
    index <- index + 1
  }
  if (!("-p" %in% names(args)) || !("-o" %in% names(args)) ||
      !("-f" %in% names(args)) || !("-n" %in% names(args))){
    stop("### Error: '-p'/'-o'/'-f'/'-n' Options Required.\n", call. = TRUE)
  }
  if (args[['-f']] == "gct" && !('-v' %in% names(args))){
    stop("### Error: '-v' Option Required With '-f' : \"gct\".\n", call. = TRUE)
  }
  if (args[['-f']] == "gct" && args[['-v']] == "1.2" && !("-e" %in% names(args))){
    stop("### Error: '-e' Option Required With '-f' : \"gct\" and '-v' : 1.2.\n", call. = TRUE)
  }
}

reorder <- function(efile, edat, msids){
  rofile <- glue("{inpdir}/exptdesign_ro.csv")
  rodata <- data.frame()
  ordids <- c()
  for (sample in msids){
    oldidx <- which(rownames(edat) == sample)
    ordids <- c(ordids, oldidx)
  }
  ordids <- c(ordids, setdiff(1:nrow(edat), ordids))
  rodata <- rbind(rodata, edat[ordids, ])
  write.csv(rodata, rofile, quote = FALSE, row.names = TRUE)
  if (tail(strsplit(efile, "[.]")[[1]], 1) == 'csv'){
    system(glue("mv {efile} {inpdir}/exptdesign_orig.csv"))
    system(glue("mv {rofile} {efile}"))
  } else{
    einp <<- args[['-e']]
    system(glue("mv {rofile} {inpdir}/edesign.csv"))
    args[['-e']] <<- glue("{inpdir}/edesign.csv")
  }
  return(rodata)
}

check_me_against_expt <- function(msids, esids, edat){
  if (length(esids) < length(msids)){
    stop("!Error: Unknown Samples in -p. Match Failed.\n", call. = TRUE)
  } else if (length(esids) > length(msids)){
    print("+Warning: Missing Samples in -p. Match Succeded.\n")
  }
  for (index in 1:length(msids)){
    if (!(msids[index] %in% esids)){
      print(msids[index])
      stop("!Error: Unknown Samples in -p. Match Failed.\n", call. = TRUE)
    } else if (msids[index] != esids[index]) freorder <<- TRUE
  }
  if (freorder) return(reorder(args[['-e']], edat, msids))
  else return(edat)
}

extract_expt_desn <- function(myfile){
  return(read.csv(myfile, header = TRUE, sep = ',', row.names = 1))
}

extract_tsi <- function(myfile){
  edata <- read.xlsx(myfile, sheet = 2, colNames = TRUE, rowNames = TRUE, check.names = TRUE)
  edata <- edata[2:nrow(edata), ] #Ignore the Data Type Row
  rownames(edata) <- gsub("-", ".", rownames(edata))
  if ("-t" %in% names(args)){
    nedat <- edata
    tedat <- edata
    rownames(nedat) <- lapply(rownames(nedat), function(x){glue(x, '.N')})
    rownames(tedat) <- lapply(rownames(tedat), function(x){glue(x, '.T')})
    edata <- rbind(tedat, nedat)
  }
  return(edata)
}

extract_cct <- function(myfile){
  cct <- read.delim(myfile, header = TRUE, sep = '\t', row.names = 1, check.names = TRUE)
  return(cct)  
}


extract_gct <- function(myfile){
  gctdata <- suppressMessages(parse.gctx(myfile))
  if (args[['-v']] != strsplit(gctdata@version, "[#]")[[1]][-1]){
    stop("### Error: Version Entered and .GCT file don't match.\n", call. = TRUE)
  }
  return(gctdata@mat)
}

extract_sct <- function(myfile){
  return(read.delim(myfile, header = TRUE, sep = '\t', row.names = 1, check.names = TRUE))
}

to_gct_3 <- function(edat, pdat) {
  cdesc <- cbind(Sample.ID=rownames(edat), edat)
  cdesc <- cdesc[1:ncol(pdat), ]
  if ("-m" %in% names(args) && tail(strsplit(args[['-m']][1], "[.]")[[1]], 1) == "sct"){
    rdesc <- extract_sct(args[['-m']][1])
  } else rdesc <- data.frame(Description=rownames(pdat))
  cdesc[] <- lapply(cdesc, as.character)
  rdesc[] <- lapply(rdesc, as.character)
  gct <- new("GCT", mat = as.matrix(pdat), cdesc = cdesc, rdesc = rdesc, 
             rid = rownames(pdat), cid = colnames(pdat), src = glue("{inpdir}/proteome.gct"))
  write.gct(gct, glue("{inpdir}/proteome.gct"), ver = 3, appenddim = FALSE)
  pinp <<- args[['-p']]
  args[['-p']] <<- glue("{inpdir}/proteome.gct")
}

to_gct_2 <- function(pdat){
  cdesc <- data.frame()
  rdesc <- data.frame(id=rownames(pdat), Description=rownames(pdat))
  rdesc[] <- lapply(rdesc, as.character)
  gct <- new("GCT", mat = as.matrix(pdat), rid = rownames(pdat), cid = colnames(pdat), rdesc = rdesc, cdesc = cdesc, src = glue("~/Documents/test.gct"))
  write.gct(gct, glue("{inpdir}/proteome.gct"), ver = 2, appenddim = FALSE)
  pinp <<- args[['-p']]
  args[['-p']] <<- glue("{inpdir}/proteome.gct")
}

convert_to_gct <- function(edat, pdat){
  if ('-e' %in% names(args)) to_gct_3(edat, pdat)
  else to_gct_2(pdat)
}

check_format <- function(myfile){
  inpdir <<- paste(head(strsplit(myfile, "[/]")[[1]], -1), collapse='/')
  srcdir <<- paste(head(strsplit(inpdir, "[/]")[[1]], -1), collapse='/')
  extn <- tail(strsplit(myfile, "[.]")[[1]], 1)
  prep <- list("gct"=extract_gct, "cct"=extract_cct)
  pdat <- prep[[extn]](myfile)
  #pdat <- pdat[, c(-4, -34, -50)]
  edat <- data.frame()
  if ("-e" %in% names(args)) {
    extr <- list("gct"=extract_expt_desn, "cct"=extract_tsi)
    edat <- extr[[extn]](args[['-e']])
    edat <- check_me_against_expt(colnames(pdat), rownames(edat), edat)
  }
  if (extn != "gct") convert_to_gct(edat, pdat)
}

create_tar <- function(){
  tardir <- glue("{strsplit(args[['-o']], '[.]')[[1]][1]}")
  system(glue("cd {srcdir}"))
  system(glue("mkdir -p {tardir}"))
  system(glue("mkdir -p {tardir}/data"))
  if ('-e' %in% names(args))
    system(glue("cp {args[['-e']]} {tardir}/data/."))
  if (freorder){
    if (args[['-f']] == "gct") system(glue("cp {inpdir}/exptdesign_orig.csv {tardir}/data/."))
    else system(glue("cp {einp} {tardir}/data/.")) 
  }
  if (args[['-f']] != "gct") system(glue("cp {pinp} {tardir}/data/."))
  if (args[["-n"]] != "T") targetdir <- "parsed-data"
  else targetdir <- "normalized-data"
  system(glue("mkdir -p {tardir}/{targetdir}"))
  system(glue("cp {args[['-p']]} {tardir}/{targetdir}/."))
  if ("-m" %in% names(args))
    for (extra in args[["-m"]]) system(glue("cp {extra} {tardir}/{targetdir}/."))
  system(glue("tar -cvf {args[['-o']]} {tardir}"), ignore.stderr = TRUE)
  system(glue("rm -rf {tardir}"))
}


main <- function(){
  set_arguments()
  check_format(args[["-p"]])
  create_tar()
}

if (!interactive()){
  main()
}
