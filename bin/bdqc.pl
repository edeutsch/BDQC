#!/usr/bin/perl
#
###############################################################################
# Program        bdqc.pl
# Author        Eric Deutsch <edeutsch@systemsbiology.org>
# Date            2017-11-06
#
# Description : This program is a simple interface to the BDQC software
#
#  bdqc.pl --help
#
###############################################################################

use strict;
use warnings;
$| = 1;

use Getopt::Long;
use FindBin;

use lib "$FindBin::Bin/../lib";

use BDQC::KB;

#### Set program name and usage banner
my $PROG_NAME = $FindBin::Script;
my $USAGE = <<EOU;
Usage: $PROG_NAME [OPTIONS]
Options:
  --help              This message
  --verbose n         Set verbosity level.  default is 0
  --quiet             Set flag to print nothing at all except errors
  --debug n           Set debug flag
  --testonly          If set, nothing is actually altered
  --debug n           Set debug level. The default is 0
  --kbRootPath x      Full or relative root path QC KB results files (file extension will be added)
  --dataDirectory x   Full or relative directory path of the data to be scanned
  --calcSignatures    Calculate file signatures for all new files in the QC KB
  --importSignatures x Import .bdqc signatures from the specified external file
  --collateData       Collate all the data from individual files in preparation for modeling
  --calcModels        Calculate file signature models for all files in the QC KB
  --showOutliers      Show all outliers in the QC KB

 e.g.:  $PROG_NAME --kbRootPath testqc --dataDirectory test1

EOU

#### Process options and print usage if an illegal options is provided
my %OPTIONS;
unless (GetOptions(\%OPTIONS,"help","verbose:i","quiet","debug:i","testonly",
                   "kbRootPath:s", "dataDirectory:s", "calcSignatures", "collateData",
                   "calcModels", "showOutliers", "importSignatures:s", 
  )) {
  print "$USAGE";
  exit 2;
}

#### Print usage on --help
if ( $OPTIONS{help} ) {
  print "$USAGE";
  exit 1;
}

main();
exit 0;


###############################################################################
sub main {

  #### Extract the run control options
  my $verbose = $OPTIONS{"verbose"} || 0;
  my $quiet = $OPTIONS{"quiet"} || 0;
  my $debug = $OPTIONS{"debug"} || 0;
  my $testonly = $OPTIONS{'testonly'} || 0;

  
  #### Create the Quality Control Knowledge Base object
  my $qckb = BDQC::KB->new();
  $qckb->createKb();

  #### If a KC QC file parameter was provided, see if there is already one to warm start with
  if ( $OPTIONS{kbRootPath} ) {
    my $result = $qckb->loadKb( kbRootPath=>$OPTIONS{kbRootPath}, skipIfFileNotFound=>1 );
    if ( $result->{status} ne 'OK' ) {
      print $result->show();
      exit 10;
    }
  }

  #### Perform the scan of the dataPath
  if ( $OPTIONS{dataDirectory} ) {
    my $result = $qckb->scanDataPath( dataDirectory=>$OPTIONS{dataDirectory}, verbose => $verbose, quiet=>$quiet, debug=>$debug );
    if ( $result->{status} ne 'OK' ) {
      print $result->show();
      exit 11;
    }
  }

  #### Calculate signatures for all files in the KB
  if ( $OPTIONS{calcSignatures} ) {
    my $result = $qckb->calcSignatures( verbose => $verbose, quiet=>$quiet, debug=>$debug );
    if ( $result->{status} ne 'OK' ) {
      print $result->show();
      exit 11;
    }
  }

  #### Important signatures from an external file into the KB
  if ( $OPTIONS{importSignatures} ) {
    my $result = $qckb->importSignatures( inputFile=>$OPTIONS{importSignatures}, verbose => $verbose, quiet=>$quiet, debug=>$debug );
    if ( $result->{status} ne 'OK' ) {
      print $result->show();
      exit 12;
    }
  }

  #### Calculate models and outliers for all files in the KB by filetype
  if ( $OPTIONS{collateData} ) {
    my $result = $qckb->collateData( verbose => $verbose, quiet=>$quiet, debug=>$debug );
    if ( $result->{status} ne 'OK' ) {
      print $result->show();
      exit 11;
    }
  }

  #### Calculate models and outliers for all files in the KB by filetype
  if ( $OPTIONS{calcModels} ) {
    my $result = $qckb->calcModels( verbose => $verbose, quiet=>$quiet, debug=>$debug );
    if ( $result->{status} ne 'OK' ) {
      print $result->show();
      exit 11;
    }
  }

  #### Show the deviations found in the data
  if ( $OPTIONS{showOutliers} ) {
    my $result = $qckb->getOutliers( verbose => $verbose, quiet=>$quiet, debug=>$debug );
    if ( $result->{status} ne 'OK' ) {
      print $result->show();
      exit 11;
    }
  }

  #### If a KC QC file parameter was provided, write out the KB
  if ( $OPTIONS{kbRootPath} ) {
    my $result = $qckb->saveKb( kbRootPath=>$OPTIONS{kbRootPath}, verbose => $verbose, quiet=>$quiet, debug=>$debug, testonly=>$testonly );
    if ( $result->{status} ne 'OK' ) {
      print $result->show();
      exit 12;
    }
  }

  return;
}

