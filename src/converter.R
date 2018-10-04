# Author: Ramani Kothadia
# Give Absolute Paths in all file location arguments
# Run ./test_run.sh for sample tests

if( !suppressMessages( require( "pacman" ) ) ) install.packages( "pacman" )
p_load( cmapR )
p_load( openxlsx )
p_load( glue )
p_load( optparse )

opt      <- list()
data.dir <- ""
freorder <- FALSE

# Set Global Variables using the command line arguments.
# Possible Future Requirements: Mandate some options, Functionality for log and coerce
set_arguments <- function() {
  optionList <- list(
    make_option( c( "-i", "--inputfile"  ), action = "store", dest = "input.file" , type = 'character', help = "Input File" ),
    make_option( c( "-a", "--inputtype"  ), action = "store", dest = "input.type" , type = 'character', help = "Input File Type" ),
    make_option( c( "-b", "--targettype" ), action = "store", dest = "target.type", type = 'character', help = "Target File Type" ),
    make_option( c( "-o", "--targetfile" ), action = "store", dest = "target.file", type = 'character', help = "Target File" ),
    make_option( c( "-d", "--datatype"   ), action = "store", dest = "data.type"  , type = 'character', help = "Data Type: Proteome, Phosphoproteome, Acetylome, etc." ),
    make_option( c( "-e", "--exptdesign" ), action = "store", dest = "expt.design", type = 'character', help = "Experiment Design File", default = ""),
    make_option( c( "-c ", "--coerce"     ), action = "store_true", dest = "coerce.flag", type = 'logical', help = "If you want to forcefully match the input file with experiment design file by removing unknown samples." ),
    make_option( c( "-t", "--tumorannot" ), action = "store_true", dest = "tumor.annot.flag", type = 'logical', help = "If samples are annoted with .T/.N."),
    make_option( c( "--log"), action = "store", dest = "log.base", type = 'integer', help = "Base of log transform on the input data."),
    make_option( c( "--sct"), action = "store", dest = "input.sct", type = 'characater', help = "sct File")
  )
  opt      <<- parse_args( OptionParser( option_list=optionList ) )
  data.dir <<- paste( head( strsplit( opt$target.file, "[/]" )[[1]], -1 ), collapse='/' )
}


# Remove samples from the input.file that cannot be found in the 
# experiment design file for testing purposes or other
coerce <- function( mat, esids ) {
  msids <- colnames( mat )
  drop <- c()
  for ( index in 1:length( msids ) )
    if ( !( msids[index] %in% esids ) )
      drop <- c( drop, index )
  if ( length( drop ) > 0 )
    mat <- mat[, -drop]
  else opt$coerce <<- FALSE
  return( mat )
}

# Extract gct@mat, gct@rdesc, gct@cdesc from tmt10.tsv files 
extract_cdap_tmt <- function() {
  # check.names = F to keep the ' ' delimiter between wanted/unwanted part of headers 
  tmt      <- read.csv( opt$input.file, header = TRUE, sep = '\t', check.names = FALSE, 
                        row.names = 1, na.strings = c(' ') )
  header.1 <- unlist( lapply( colnames(tmt), 
                              function(x) {
                                return( strsplit( x, split = ' ' )[[1]][1] )
                              } ) )
  header.2 <- unlist( lapply( colnames(tmt), 
                              function(x) {
                                s <- strsplit( x, split = ' ' )[[1]]
                                s <- s[2:length(s)]
                                return( paste(s, collapse = '.') )
                              } ) )
  n.samples <- 0
  if ( opt$data.type == "proteome" ){
    # header.2 edit is unnecessary at this point. 
    # Order Imp: Drop unwanted columns => Rename columns without "Log.Ratio" suffix => 
    # Extract cdesc => Cut cdesc from gct@mat
    drop            <- which( header.2 == "Unshared.Log.Ratio" )
    n.samples       <- length( drop )
    header.1        <- header.1[-drop] 
    tmt             <- tmt[, -drop]
    colnames( tmt ) <- make.names( header.1 )
    cdesc           <- data.frame( tmt[c(1:3), c(1:n.samples)] )
    tmt             <- tmt[-c(1:3), ]
  } else if ( opt$data.type == "phosphoproteome" ){
    n.samples       <- length( which( header.2 == "Log.Ratio" ) )
    # No Column Description present for Phospho
    cdesc           <- data.frame()
    colnames( tmt ) <- make.names( header.1 )
  }
  if ( ( n.samples + 1 ) <= length( tmt ) ) {
    rdesc <- data.frame( tmt[, ( n.samples + 1 ):length( tmt )] )
    tmt   <- tmt[, -( ( n.samples + 1 ):length( tmt ) )]
  } else rdesc <- data.frame()
  # Transpose cdesc to match GCT class format
  return( list( mat = tmt, rdesc = rdesc, cdesc = as.data.frame( t( cdesc ) ) ) )
}


# read the cct file into a data frame for further processing
extract_cct <- function(){
  cct <- read.delim( opt$input.file, header = TRUE, sep = '\t', row.names = 1, check.names = TRUE )
  return( list( mat = cct, rdesc = data.frame(), cdesc = data.frame() ) )
}

# read the experiment design csv file associated with the gct -omics file
extract_expt_desn <- function() {
  return( read.csv( opt$expt.design, header = TRUE, sep = ',', row.names = 1 ) )
}

# Rewrite duplicates in the original ordering with the foll. format
# ['rain', 'wind', 'smog', 'rain', 'wind', 'hail'] =>
# ['rain.1', 'wind.1', 'smog', 'rain.2', 'wind.2', 'hail']
# which is not possible with the help of ?duplicated / ?unique
manage_duplicates <- function( esids ) {
  esids  <- as.character( esids )
  counts <- list()
  modify <- c()
  for ( sample in esids ) {
    if ( sample %in% names( counts ) && counts[[sample]] == 1 ) {
      firstIdx         <- which( modify == sample )
      modify[firstIdx] <- glue( "{modify[firstIdx]}.1" )
      modify           <- c( modify, glue( "{sample}.2" ) )
      counts[[sample]] <- 2
    } else if ( sample %in% names( counts ) ) {
      modify           <- c( modify, glue( "{sample}.{counts[[sample]] + 1}" ) )
      counts[[sample]] <- counts[[sample]] + 1
    } else{
      modify           <- c( modify, sample )
      counts[[sample]] <- 1
    }
  }
  return( modify )
}

# Parse the given sample.txt file and rewrite in the PGDAC exptdesign .csv format
unroll_cdap_expt_design <- function() {
  if ( exists( "ecsv" ) ) rm( "ecsv" )
  expt     <- read.delim( opt$expt.design, sep = '\t', header = TRUE )
  # beg.chan & end.chan dependent on the current sample.txt format
  beg.chan <- which( colnames( expt ) == "X126" )
  end.chan <- which( colnames( expt ) == "X130C" )
  for ( col in beg.chan:end.chan )
    for ( row in 1:nrow( expt ) ) {
      temp <- data.frame( list(
        SampleId         = expt[row, col], 
        FileNameRegEx    = expt[row, which( colnames( expt ) == "FileNameRegEx" )],
        AnalyticalSample = expt[row, which( colnames( expt ) == "AnalyticalSample" )], 
        Channel          = strsplit( colnames( expt )[col], split = 'X')[[1]][-1],
        LabelReagent     = expt[row, which( colnames( expt ) == "LabelReagent" )],
        Ratios           = paste( strsplit( as.character( 
          expt[row, which( colnames( expt ) == "Ratios" )] ), 
          split = ',')[[1]], collapse = ';' ) ) )
      if ( !( exists( "ecsv" ) ) )  ecsv <- temp
      else  ecsv <- rbind( ecsv, temp ) # Re-visit: When is this applicable?
    }
  rownames( ecsv ) <- make.names( manage_duplicates( ecsv[,1] ) )
  ecsv$SampleId    <- rownames( ecsv )
  # row.names = F as column of SampleId appended to ecsv ( for keeping column name SampleId )
  write.csv( ecsv, file = glue( "{data.dir}/exptdesign.csv" ), quote = FALSE, row.names = FALSE)
  opt$expt.design  <<- glue( "{data.dir}/exptdesign.csv" )
}

# read the experiment design tsi file associated with the cct -omics file.
# In case the '-t' is present in command line arguments, modify the experiment design file by duplicating current rows,
# appending it one below another where top half's row names have .T suffixes and bottom half's .N suffixes. Replace any hyphens with '.'
extract_tsi <- function() {
  edata             <- read.xlsx( opt$expt.design, sheet = 2, colNames = TRUE, rowNames = TRUE, check.names = TRUE )
  edata             <- edata[2:nrow(edata), ] #Ignore the Data Type Row
  rownames( edata ) <- gsub( "-", ".", rownames( edata ) )
  if ( 'tumor.annot.flag' %in% names( opt ) ) {
    nedat             <- edata
    tedat             <- edata
    rownames( nedat ) <- lapply( rownames( nedat ), function( x ){ glue( x, '.N' ) } )
    rownames( tedat ) <- lapply( rownames( tedat ), function( x ){ glue( x, '.T' ) } )
    edata             <- rbind( tedat, nedat )
  }
  return( edata )
}

# Reorder exptdesign file to match the order of samples in the tmt10.tsv file
# Rename the original exptdesign file to exptdesign_orig & reordered exptdesign as exptdesign
reorder <- function( efile, edat, msids ){
  rofile <- glue( "{data.dir}/exptdesign_ro.csv" )
  rodata <- data.frame()
  ordids <- c()
  for ( sample in msids ){
    oldidx <- which( rownames( edat ) == sample )
    ordids <- c( ordids, oldidx )
  }
  ordids <- c( ordids, setdiff( 1:nrow( edat ), ordids ) )
  rodata <- rbind( rodata, edat[ordids, ] )
  rodata <- cbind( SampleId = rownames( rodata ), rodata )
  write.csv( rodata, rofile, quote = FALSE, row.names = FALSE )
  if ( tail( strsplit( efile, "[.]" )[[1]], 1 ) == 'csv' ) {
    system( glue( "mv {efile} {data.dir}/exptdesign_orig.csv" ) )
    system( glue( "mv {rofile} {efile}" ) )
  } else{
    system( glue( "mv {rofile} {data.dir}/exptdesign.csv" ) )
    opt$expt.design <<- glue( "{data.dir}/exptdesign.csv" )
  }
  return( rodata )
}


# Check if there are samples in tmt10.tsv that are absent in exptdesign and if
# they're in the same order as each other
check_me_against_expt <- function( msids, esids, edat ) {
  if ( length( esids ) < length( msids ) ) {
    stop( "!Error: Unknown samples in --inputfile. Match Failed.\n", call. = TRUE )
  } else if ( length( esids ) > length( msids ) ) {
    print( "+Warning: Missing samples in --inputfile. Match Succeded.\n" )
  }
  for ( index in 1:length( msids ) ){
    if ( !( msids[index] %in% esids ) ){
      stop( glue( "!Error: Unknown Samples in --inputfile. ({msids[index]}) Match Failed.\n" ), call. = TRUE )
    } else if ( msids[index] != esids[index] ) freorder <<- TRUE
  }
  if ( freorder ) return( reorder( opt$expt.design, edat, msids ) )
  else return( edat )
}


# Add sample meta-information from the exptdesign.csv file to cdesc
get_cdesc_from_expt <- function( mydata, edat ) {
  if ( nrow( mydata$cdesc ) > 0 ) {
    mydata$cdesc <- cbind( edat, mydata$cdesc )
  } else mydata$cdesc <- edat
  mydata$cdesc <- mydata$cdesc[1:ncol( mydata$mat ), ]
  return( mydata )
}


# Write a GCT file given ingredients for gct class and the gct version
write_gct <- function( gct, ver ){
  gct$cdesc[] <- lapply( gct$cdesc, as.character )
  gct$rdesc[] <- lapply( gct$rdesc, as.character )
  gctclass    <- new( "GCT", mat = as.matrix( gct$mat ), cdesc = gct$cdesc, rdesc = gct$rdesc, 
                      rid = rownames( gct$mat ), cid = colnames( gct$mat ), src = opt$target.file )
  write.gct( gctclass, opt$target.file, ver = ver, appenddim = FALSE )  
}

# fill the cdesc and rdesc, create a new gct object, write it into a file and save old addresses
cct_get_rdesc_3 <- function( edat, cctdata ){
  if ( opt$data.type == "proteome" )
    cctdata$rdesc <- data.frame( GeneSymbol = rownames( cctdata$mat ) )
  else if ( opt$data.type == "phosphoproteome" )
    cctdata$rdesc <- data.frame( GeneSymbol = unlist( lapply( rownames( cctdata$mat ), 
                                                      function( x ){ strsplit( x, "[-]" )[[1]][1] } ) ) )
  else
    cctdata$rdesc <- data.frame( Description = rownames( cctdata$mat ) ) 
  if ( 'input.sct' %in% names( opt ) )
    cctdata$rdesc <- cbind( cctdata$rdesc, extract_sct( opt$sct ) )
  return ( cctdata )
}

# Get rdesc specific for cdap type files
cdap_get_rdesc <- function( tmtdata ) {
  if ( opt$data.type == 'proteome' )
    desc <- data.frame( GeneSymbol = rownames( tmtdata$mat ), row.names = rownames( tmtdata$mat ) )
  else desc <- data.frame( id = rownames( tmtdata$mat ), Description = rownames( tmtdata$mat ) )
  if ( nrow( tmtdata$rdesc ) == 0 )
    tmtdata$rdesc <- desc
  else if ( nrow( tmtdata$rdesc ) > 0 )
    tmtdata$rdesc <- cbind( desc, tmtdata$rdesc )
  return( tmtdata )
}

# fill the cdesc and rdesc, create a new gct object, write it into a file, save old addresses
cct_get_rdesc_2 <- function( cctdata ){
  cctdata$rdesc <- data.frame( id = rownames( cctdata$mat ), Description = rownames( cctdata$mat ) )
  return( cctdata )
}


cdap_main <- function() {
  tmtdata <- extract_cdap_tmt()
  if ( 'log.base' %in% names( opt ) )
    tmtdata$mat   <- as.data.frame( lapply( tmtdata$mat, function( x ) log( x, as.numeric( opt$log ) ) ), 
                                    row.names = rownames( tmtdata$mat ) )
  if ( opt$expt.design != "" ) {
    unroll_cdap_expt_design()
    expdata <- extract_expt_desn()
    if ( 'coerce.flag' %in% names( opt ) )
      tmtdata$mat <- coerce( tmtdata$mat, rownames( expdata ) )
    expdata <- check_me_against_expt( colnames( tmtdata$mat ), rownames( expdata ), expdata )
    tmtdata <- get_cdesc_from_expt( tmtdata, expdata )
  }
  tmtdata <- cdap_get_rdesc( tmtdata )
  if ( nrow( tmtdata$cdesc ) == 0 && 
       all( colnames( tmtdata$rdesc ) == c( "id", "Description" ) ) )
    write_gct( tmtdata, 2)
  else write_gct( tmtdata, 3)
}

cct_main <- function() {
  cctdata <- extract_cct()
  if ( 'log.base' %in% names( opt ) )
    cctdata$mat   <- as.data.frame( lapply( cctdata$mat, function( x ) log( x, as.numeric( opt$log ) ) ), 
                                    row.names = rownames( cctdata$mat ) )
  if ( opt$expt.design != "" ) {
    expdata <- extract_tsi()
    if ( 'coerce.flag' %in% names( opt ) )
      cctdata$mat <- coerce( cctdata$mat, rownames( expdata ) )
    expdata <- check_me_against_expt( colnames( cctdata$mat ), rownames( expdata ), expdata )
    cctdata <- get_cdesc_from_expt( cctdata, expdata )
    cctdata <- cct_get_rdesc_3( expdata, cctdata )
    write_gct( cctdata, 3 )
  } else {
    cctdata <- cct_get_rdesc_2( cctdata )
    write_gct( cctdata, 2)
  }
}

main <- function(){
  set_arguments()
  print(opt)
  if ( opt$input.type == 'cdap' )  cdap_main()
  if ( opt$input.type == 'cct'  )  cct_main()
}

if ( !interactive() ) {
  main()
}
