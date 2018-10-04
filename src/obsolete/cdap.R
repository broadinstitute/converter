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
    make_option( c( "-if", "--inputfile"  ), action = "store", dest = "input.file" , type = 'character', help = "Input File" ),
    make_option( c( "-it", "--inputtype"  ), action = "store", dest = "input.type" , type = 'character', help = "Input File Type" ),
    make_option( c( "-tt", "--targettype" ), action = "store", dest = "target.type", type = 'character', help = "Target File Type" ),
    make_option( c( "-tf", "--targetfile" ), action = "store", dest = "target.file", type = 'character', help = "Target File" ),
    make_option( c( "-dt", "--datatype"   ), action = "store", dest = "data.type"  , type = 'character', help = "Data Type: Proteome, Phosphoproteome, Acetylome, etc." ),
    make_option( c( "-ed", "--exptdesign" ), action = "store", dest = "expt.design", type = 'character', help = "Experiment Design File", default = ""),
    make_option( c( "-c ", "--coerce"     ), action = "store_true", dest = "coerce.flag", type = 'logical', help = "If you want to forcefully match the input file with experiment design file by removing unknown samples." )
    #make_option(c("-n" , "--normalized"), action="store_true", dest="norm.flag", type='logical', help="If data is normalized."),
    #make_option(c("-ta", "--tumorannot"), action="store_true", dest="tumor.annot.flag", type='logical', help="If samples are annoted with .T/.N."),
    #make_option(c("--log"), action="store", dest="log.base", type='integer', help="Base of log transform on the input data."),
    #make_option(c("--sct"), action="store", dest="input.sct", type='characater', help="sct File")
  )
  opt      <<- parse_args( OptionParser( option_list=optionList ) )
  data.dir <<- paste( head( strsplit( opt$target.file, "[/]" )[[1]], -1 ), collapse='/' )
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
    stop( "!Error: Unknown Samples in -p. Match Failed.\n", call. = TRUE )
  } else if ( length( esids ) > length( msids ) ) {
    print( "+Warning: Missing Samples in -p. Match Succeded.\n" )
  }
  for ( index in 1:length( msids ) ){
    if ( !( msids[index] %in% esids ) ){
      stop( glue( "!Error: Unknown Samples in -p. ({msids[index]}) Match Failed.\n" ), call. = TRUE )
    } else if ( msids[index] != esids[index] ) freorder <<- TRUE
  }
  if ( freorder ) return( reorder( opt$expt.design, edat, msids ) )
  else return( edat )
}

# read the experiment design csv file associated with the gct -omics file
extract_expt_desn <- function() {
  return( read.csv( opt$expt.design, header = TRUE, sep = ',', row.names = 1 ) )
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
  return( list( tmt = tmt, rdesc = rdesc, cdesc = as.data.frame( t( cdesc ) ) ) )
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

# Convert extracted data objects to a GCT class object and write it to a gct file
cdap_to_gct <- function( mat, rdesc, cdesc ) {
  if ( opt$data.type == 'proteome' )
    desc <- data.frame( GeneSymbol = rownames( mat ), row.names = rownames( mat ) )
  else desc <- data.frame( id = rownames( mat ), Description = rownames( mat ) )
  if ( nrow( cdesc ) == 0 && nrow( rdesc ) == 0 )
    ver <- 2
  else ver <- 3
  if ( nrow( rdesc ) == 0 )
    rdesc <- desc
  else if ( nrow( rdesc ) > 0 )
    rdesc <- cbind( desc, rdesc )
  cdesc[] <- lapply( cdesc, as.character )
  rdesc[] <- lapply( rdesc, as.character )
  gct <- new( "GCT", mat = as.matrix( mat ), cdesc = cdesc , rdesc = rdesc, 
              rid = rownames( mat ), cid = colnames( mat ), src = opt$target.file )
  write.gct( gct, opt$target.file, ver = ver, appenddim = FALSE )
}

# Add sample meta-information from the exptdesign.csv file to cdesc
get_cdesc_from_expt <- function( cdesc, edat ) {
  if ( nrow( cdesc ) > 0 ) {
    cdesc <- cbind( edat, cdesc )
  } else cdesc <- edat
  return( cdesc )
}

main <- function(){
  set_arguments()
  tmtdata <- extract_cdap_tmt()
  if ( opt$expt.design != "" ) {
    unroll_cdap_expt_design()
    expdata       <- extract_expt_desn()
    re.edat       <- check_me_against_expt( colnames( tmtdata$tmt ), rownames( expdata ), expdata )
    tmtdata$cdesc <- get_cdesc_from_expt( tmtdata$cdesc, re.edat )
  }
  cdap_to_gct( tmtdata$tmt, tmtdata$rdesc, tmtdata$cdesc )
}

if ( !interactive() ) {
  main()
}
