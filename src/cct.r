if( !suppressMessages( require( "pacman" ) ) ) install.packages( "pacman" )
p_load( cmapR )
p_load( openxlsx )
p_load( glue )
p_load( optparse )
options( stringsAsFactors = FALSE )

opt      <- list()
data.dir <- ""
freorder <- FALSE
opt$input.type  <- "cct"
opt$target.type <- "gct"

#opt$input.file <- "RNAseq_RSEM_UQ_Tumor.cct"
#opt$target.file <- glue( "{getwd()}/proteome.gct" )
#opt$version <- 3
#opt$annot.file <- "Meta_table.tsv"
#opt$coerce.flag <- TRUE

set_arguments <- function() 
{
  optionList <- list(
    make_option( c( "-i", "--inputfile" ), action = "store", 
                 dest = "input.file" , type = 'character', 
                 help = "Full path of input TSV/CCT file." ),
    make_option( c( "-o", "--targetfile" ), action = "store", 
                 dest = "target.file", type = 'character', 
                 help = "Full path of target GCT file." ),
    make_option( c( "-v", "--version" ), action = "store", 
                 dest = "version", type = 'character', 
                 help = "Version of \"-o\" (2 / 3)." ),
    make_option( c( "-a", "--annotfile" ), action = "store", 
                 dest = "annot.file", type = 'character', 
                 help = "Full path of annotation file." ),
    make_option( c( "-r", "--rdesc" ), action = "store", 
                 dest = "rdesc.ends.at", type = 'integer',
                 help = "Last column # of \"rdesc\" in \"-i\"." ),
    make_option( c( "-g", "--genecol" ), action = "store", 
                 dest = "gene.col", type = 'character',
                 help = "Column name in \"-i\" that has gene names." ),
    make_option( c( "-c", "--coerce" ), action = "store_true", 
                 dest = "coerce.flag", type = 'logical', default = F,
                 help = "Force match samples from \"-i\" and \"-a\"."),
    make_option( c( "-t", "--tumorannot" ), action = "store_true", 
                 dest = "tumor.annot.flag", type = 'logical', default = F,
                 help = "Create sample IDs with .T/.N suffixes." )
  )
  opt <<- parse_args( OptionParser( option_list=optionList ) )
  data.dir <<- paste( head( strsplit( opt$target.file, "[/]" )[[1]], -1 ), 
                      collapse='/' )
}

# Write a GCT file given ingredients for gct class and the gct version
write_gct <- function( gct, ver )
{
  gct$cdesc[] <- lapply( gct$cdesc, as.character )
  gct$rdesc[] <- lapply( gct$rdesc, as.character )
  gctclass <- new( "GCT", 
                   mat = as.matrix( gct$mat ), 
                   cdesc = gct$cdesc, 
                   rdesc = gct$rdesc, 
                   rid = rownames( gct$mat ), 
                   cid = colnames( gct$mat ), 
                   src = opt$target.file )
  write.gct( gctclass, opt$target.file, ver = ver, appenddim = FALSE )  
}

collect_rdesc_2 <- function( cct.data )
{
  cct.data$rdesc <- data.frame( id = rownames( cct.data$mat ), 
                                Description = rownames( cct.data$mat ) )
  return( cct.data )
}

collect_rdesc_3 <- function( cct.data, annot.mat )
{
  if ( "rdesc.ends.at" %in% names( opt ) && "gene.col" %in% names( opt ) )
  {
    gene.col.id <- which( colnames( cct.data$rdesc ) == opt$gene.col )
    colnames( cct.data$rdesc )[gene.col.id] <- "geneSymbol"
  } else cct.data$rdesc <- data.frame( geneSymbol = rownames( cct.data$mat ) ) 
  return ( cct.data )
}

# Add sample meta-information from the exptdesign.csv file to cdesc
collect_cdesc <- function( cct.data, annot.mat ) 
{
  if ( nrow( cct.data$cdesc ) > 0 ) 
    cct.data$cdesc <- cbind( annot.mat, cct.data$cdesc )
  else cct.data$cdesc <- annot.mat
  cct.data$cdesc <- cct.data$cdesc[1:ncol( cct.data$mat ), ]
  return( cct.data )
}

# Reorder annotation file to match the order of samples in the tmt10.tsv file
reorder <- function( annot.file, annot.mat, cct.ids )
{
  reordered.file <- glue( "{data.dir}/annotation_reordered.csv" )
  old.order <- c()
  for ( sample in cct.ids )
  {
    old.idx <- which( rownames( annot.mat ) == sample )
    old.order <- c( old.order, old.idx )
  }
  # not needed anymore since we are intersecting and not doing one way join
  # old.order <- c( old.order, setdiff( 1:nrow( annot.mat ), old.order ) )
  reordered.data <- as.data.frame( annot.mat[old.order, ] )
  reordered.data <- cbind( Sample.ID = rownames( reordered.data ), 
                           reordered.data )
  write.csv( reordered.data, reordered.file, quote = TRUE, row.names = FALSE )
  if ( tail( strsplit( annot.file, "[.]" )[[1]], 1 ) == 'csv' ) 
  {
    system( glue( "mv {annot.file} {data.dir}/annotation.original.csv" ) )
    system( glue( "mv {reordered.file} {annot.file}" ) )
  } else
  {
    system( glue( "mv {reordered.file} {data.dir}/annotation.csv" ) )
    opt$annot.file <<- glue( "{data.dir}/annotation.csv" )
  }
  return( reordered.data )
}

# Keep samples present in annotation and input file both only
# Remove others
coerce <- function( cct.mat, annot.mat  ) 
{
  drop <- c()
  keep.samples <- intersect( colnames( cct.mat ), rownames( annot.mat ) )
  keep.ids <- unlist( lapply( keep.samples, function( x ) 
    which( colnames( cct.mat ) == x ) ) )
  cct.mat <- cct.mat[, keep.ids]
  keep.ids <- unlist( lapply( keep.samples, function( x )
    which( rownames( annot.mat ) == x ) ) )
  annot.mat <- annot.mat[keep.ids, ]
  drop <- setdiff( colnames( cct.mat ), keep.samples )
  if ( length( drop ) > 0 )
    print( glue( 
      "No annotations for: {paste0( drop, collapse = ',' )}. (Dropped)" ) )
  drop <- setdiff( rownames( annot.mat ), keep.samples )
  if ( length( drop ) > 0 )
    print( glue( 
      "No input data for: {paste0( drop, collapse = ',' )}. (Dropped)" ) )
  return( list( cct=cct.mat, annot=annot.mat ) )
}

# read the experiment design tsi file associated with the cct -omics file.
# In case the '-t' is present in command line arguments, modify the annotation
# file by duplicating current rows, appending it one below another where top 
# half's row names have .T suffixes and bottom half's .N suffixes. 
# Replace any hyphens with '.'
extract_annot <- function() 
{
  ## no need to fix the xlsx format, Use a simple .tsv file as input
  annot.mat <- read.delim( file = opt$annot.file, header = T, sep = '\t', 
                           row.names = 1, check.names = T )
  # out-dated
  # annot.mat <- annot.mat[2:nrow( annot.mat ), ] #Ignore the Data Type Row
  rownames( annot.mat ) <- gsub( "-", ".", rownames( annot.mat ) )
  if ( 'tumor.annot.flag' %in% names( opt ) ) 
  {
    n.dat <- annot.mat
    t.dat <- annot.mat
    rownames( n.dat ) <- lapply( rownames( n.dat ), 
                                 function( x ){ glue( x, '.N' ) } )
    rownames( t.dat ) <- lapply( rownames( t.dat ), 
                                 function( x ){ glue( x, '.T' ) } )
    annot.mat <- rbind( t.dat, n.dat )
  }
  return( annot.mat )
}

# read the cct file into a data frame for further processing
extract_cct <- function()
{
  cct <- read.delim( opt$input.file, header = TRUE, sep = '\t', 
                     row.names = 1, check.names = TRUE )
  if ( "rdesc.ends.at" %in% names( opt ) )
  {
    rdesc <- as.data.frame( cct[, 1:opt$rdesc.ends.at] )
    colnames( rdesc ) <- colnames( cct )[1:opt$rdesc.ends.at]
    rownames( rdesc ) <- rownames( cct )
    if ( opt$rdesc.ends.at > 2 )
      cct <- cct[, -c( seq( 2, opt$rdesc.ends.at ) )]
    else if ( opt$rdesc.ends.at == 2 )
      cct <- cct[, -2]
  } else rdesc <- data.frame()
  return( list( mat = cct, rdesc = rdesc, cdesc = data.frame() ) )
}

cct_main <- function() 
{
  cct.data <- extract_cct()
  ## no need to have log function here
  ## has to have the annotation file
  annot.mat <- extract_annot()
  if ( 'coerce.flag' %in% names( opt ) )
  {
    data <- coerce( cct.data$mat, annot.mat )
    cct.mat <- data$cct
    annot.mat <- data$annot
  }
  annot.mat <- reorder( opt$annot.file, annot.mat, colnames( cct.data$mat ) )
  
  if( opt$version == 3 )
  {
    cct.data <- collect_cdesc( cct.data, annot.mat )
    cct.data <- collect_rdesc_3( cct.data, annot.mat )
  } else cct.data <- collect_rdesc_2( cct.data )
  write_gct( cct.data, opt$version )
}

main <- function(){
  set_arguments()
  cct_main()
}

if ( !interactive() ) {
  main()
}
