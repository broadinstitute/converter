if(!suppressMessages(require("pacman"))) install.packages("pacman")
p_load(cmapR)
p_load(openxlsx)
p_load(glue)
p_load(optparse)

args <- list()
freorder <- FALSE
inpdir <- ""
pinp <- c()
einp <- ""

# set command line arguments in the appropriate variables
set_arguments <- function() {
  sysargs <- commandArgs(trailingOnly = TRUE)
  sysalen <- length(sysargs)
  valid   <- c('-p', '-e', '-o', '-m', '-v', '-n', '-f', '-t', 
               '-dt', '-rna', '-cna', '-c', '-log')
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
  if (!( "-p" %in% names(args)) || !( "-o" %in% names(args)) || !( "-f" %in% names(args)) ||
      !( "-cna" %in% names(args)) || !( "-rna" %in% names(args)) || !( "-dt" %in% names(args))){
    stop("### Error: '-p'/'-o'/'-f'/'-rna'/'-cna'/'-dt' Options Required.\n", call. = TRUE)
  }
  if (args[['-f']] == "gct" && !('-v' %in% names(args))){
    stop("### Error: '-v' Option Required With '-f' : \"gct\".\n", call. = TRUE)
  }
  if (args[['-f']] == "gct" && args[['-v']] == "1.2" && !("-e" %in% names(args))){
    stop("### Error: '-e' Option Required With '-f' : \"gct\" and '-v' : 1.2.\n", call. = TRUE)
  }
}

# reorder experiment design file in case order doesn't match with the order of samples in the -omics file. Append extra samples at the bottom.
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
    system(glue("mv {rofile} {inpdir}/exptdesign.csv"))
    args[['-e']] <<- glue("{inpdir}/exptdesign.csv")
  }
  return(rodata)
}

# check if there are any unaccounted samples in the -omics file that are absent in the experiment design file.
# In that case report an error. If there is an sample order mismatch between the -omics and experiment design file, reorder the latter.
# In case there are samples absent in -omics but present in experiment design, report a warning.
check_me_against_expt <- function(msids, esids, edat){
  if (length(esids) < length(msids)){
    stop("!Error: Unknown Samples in -p. Match Failed.\n", call. = TRUE)
  } else if (length(esids) > length(msids)){
    print("+Warning: Missing Samples in -p. Match Succeded.\n")
  }
  for (index in 1:length(msids)){
    if (!(msids[index] %in% esids)){
      stop(glue("!Error: Unknown Samples in -p. ({msids[index]}) Match Failed.\n"), call. = TRUE)
    } else if (msids[index] != esids[index]) freorder <<- TRUE
  }
  if (freorder) return(reorder(args[['-e']], edat, msids))
  else return(edat)
}

# read the experiment design csv file associated with the gct -omics file
extract_expt_desn <- function(myfile){
  return(read.csv(myfile, header = TRUE, sep = ',', row.names = 1))
}

# read the experiment design tsi file associated with the cct -omics file.
# In case the '-t' is present in command line arguments, modify the experiment design file by duplicating current rows,
# appending it one below another where top half's row names have .T suffixes and bottom half's .N suffixes. Replace any hyphens with '.'
extract_tsi <- function(myfile){
  edata <- read.xlsx(myfile, sheet = 2, colNames = TRUE, rowNames = TRUE, check.names = TRUE)
  edata <- edata[2:nrow(edata), ] #Ignore the Data Type Row
  rownames(edata) <- gsub("-", ".", rownames(edata))
  if ("-t" %in% names(args) && args[['-t']] == "T"){
    nedat <- edata
    tedat <- edata
    rownames(nedat) <- lapply(rownames(nedat), function(x){glue(x, '.N')})
    rownames(tedat) <- lapply(rownames(tedat), function(x){glue(x, '.T')})
    edata <- rbind(tedat, nedat)
  }
  return(edata)
}

# read the cct file into a data frame for further processing
extract_cct <- function(myfile){
  cct <- read.delim(myfile, header = TRUE, sep = '\t', row.names = 1, check.names = TRUE)
  return(cct)
}

# read the gct file, cross check to confirm version matches between entered -omics file and user-inputted version
extract_gct <- function(myfile){
  gctdata <- suppressMessages(parse.gctx(myfile))
  if (args[['-v']] != strsplit(gctdata@version, "[#]")[[1]][-1]){
    stop("### Error: Version Entered and .GCT file don't match.\n", call. = TRUE)
  }
  return(as.data.frame(gctdata@mat))
}

# read the sct file to fill the rdesc of the to-be created gct object
extract_sct <- function(myfile){
  return(read.delim(myfile, header = TRUE, sep = '\t', row.names = 1, check.names = TRUE))
}

# fill the cdesc and rdesc, create a new gct object, write it into a file and save old addresses
to_gct_3 <- function(edat, pdat){
  pinp <<- c(pinp, args[['-p']])
  args[['-p']] <<- glue("{inpdir}/{args[['-dt']]}.gct")
  cdesc <- cbind(Sample.ID=rownames(edat), edat)
  cdesc <- cdesc[1:ncol(pdat), ]
  if (args[['-dt']] == "proteome"){
    rdesc <- data.frame(GeneSymbol=rownames(pdat))
  } else if (args[['-dt']] == "phosphoproteome"){
    genesymbol <- unlist(lapply(rownames(pdat), function(x){strsplit(x, "[-]")[[1]][1]}))
    rdesc <- data.frame(GeneSymbol=genesymbol)
  } else { 
    rdesc <- data.frame(Description=rownames(pdat)) 
  }
  if ("-m" %in% names(args) && tail(strsplit(args[['-m']][1], "[.]")[[1]], 1) == "sct"){
    if(exists("rdesc")) rdesc <- cbind(rdesc, extract_sct(args[['-m']][1]))
    else rdesc <- extract_sct(args[['-m']][1])
  }
  cdesc[] <- lapply(cdesc, as.character)
  rdesc[] <- lapply(rdesc, as.character)
  gct <- new("GCT", mat = as.matrix(pdat), cdesc = cdesc, rdesc = rdesc,
             rid = rownames(pdat), cid = colnames(pdat), src = args[['-p']])
  write.gct(gct, args[['-p']], ver = 3, appenddim = FALSE)
}

# fill the cdesc and rdesc, create a new gct object, write it into a file, save old addresses
to_gct_2 <- function(pdat){
  pinp <<- c(pinp, args[['-p']])
  args[['-p']] <<- glue("{inpdir}/{args[['-dt']]}.gct")
  cdesc <- data.frame()
  rdesc <- data.frame(id=rownames(pdat), Description=rownames(pdat))
  rdesc[] <- lapply(rdesc, as.character)
  gct <- new("GCT", mat = as.matrix(pdat), rid = rownames(pdat), cid = colnames(pdat), 
             rdesc = rdesc, cdesc = cdesc, src = args[['-p']])
  write.gct(gct, args[['-p']], ver = 2, appenddim = FALSE)
}

# convert to gct 1.2 if no experiment design file exists; otherwise to gct 1.3
other_to_gct <- function(edat, pdat){
  if ('-e' %in% names(args)) to_gct_3(edat, pdat)
  else to_gct_2(pdat)
}

gct_modified <- function(pdat){
  gctdata <- suppressMessages(parse.gctx(args[['-p']]))
  pinp <<- c(pinp, args[['-p']])
  args[['-p']] <<- glue("{inpdir}/{args[['-dt']]}-modified.gct")
  gctdata@mat <- as.matrix(pdat)
  version <- as.numeric(strsplit(gctdata@version, "[.]")[[1]][2])
  if (version == 2){
    gctdata@rdesc <- data.frame(id=rownames(pdat), Description=rownames(pdat))
    gctdata@rdesc[] <- lapply(gctdata@rdesc, as.character)
  }
  write.gct(gctdata, args[['-p']], ver = version, appenddim = FALSE)
}

coerce <- function(pdat, esids){
  psids <- colnames(pdat)
  drop <- c()
  for (index in 1:length(psids))
    if (!(psids[index] %in% esids))
      drop <- c(drop, index)
  if (length(drop) > 0)
    pdat <- pdat[, -drop]
  else args[['-c']] <<- "F"
  return(pdat)
}

# collect data from -omics and experiement design; convert to gct in case of cct
check_format <- function(myfile){
  inpdir <<- paste(head(strsplit(myfile, "[/]")[[1]], -1), collapse='/')
  extn <- tail(strsplit(myfile, "[.]")[[1]], 1)
  prep <- list("gct"=extract_gct, "cct"=extract_cct)
  pdat <- prep[[extn]](myfile)
  edat <- data.frame()
  if ("-e" %in% names(args)) {
    extr <- list("gct"=extract_expt_desn, "cct"=extract_tsi)
    edat <- extr[[extn]](args[['-e']])
    if ('-c' %in% names(args) && args[['-c']] == 'T')
      pdat <- coerce(pdat, rownames(edat))
    edat <- check_me_against_expt(colnames(pdat), rownames(edat), edat)
  }
  if ('-log' %in% names(args))
    pdat <- as.data.frame(lapply(pdat, function(x) log(x, as.numeric(args[['-log']]))), 
                          row.names = rownames(pdat))
  if (extn != "gct") other_to_gct(edat, pdat) # incorporates coerced and log canges
  else if (('-c' %in% names(args) && args[['-c']] == "T") || '-log' %in% names(args)) 
    gct_modified(pdat)
}

# create the output tarball with data, parsed-data OR normalized-data as subdirectories depending on flags
create_tar <- function(){
  tardir <- glue("{strsplit(args[['-o']], '[.]')[[1]][1]}")
  system(glue("cd {inpdir}"))
  system(glue("mkdir -p {tardir}"))
  system(glue("mkdir -p {tardir}/data"))
  if ('-e' %in% names(args))
    system(glue("cp {args[['-e']]} {tardir}/data/."))
  if (freorder){
    if (args[['-f']] == "gct") system(glue("cp {inpdir}/exptdesign_orig.csv {tardir}/data/."))
    else system(glue("cp {einp} {tardir}/data/."))
  }
  if (length(pinp) > 0)
    for (index in 1:length(pinp))
      system(glue("cp {pinp[index]} {tardir}/data/."))
  system(glue("cp {args[['-rna']]} {tardir}/data/rna-data.gct"))
  system(glue("cp {args[['-cna']]} {tardir}/data/cna-data.gct"))
  targetgct <- ""
  if ('-n' %in% names(args) && args[["-n"]] == "T") {
    targetdir <- "normalized-data"
    targetgct <- glue("{args[['-dt']]}-ratio-norm-NArm.gct")
  } else {
    targetdir <- "parsed-data"
    targetgct <- glue("{args[['-dt']]}-ratio.gct")
  }
  system(glue("mkdir -p {tardir}/{targetdir}"))
  system(glue("cp {args[['-p']]} {tardir}/{targetdir}/{targetgct}"))
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
