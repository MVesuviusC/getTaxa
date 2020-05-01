#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Long;
use Pod::Usage;
use LWP::Simple;
use DBI;

##############################
# By Matt Cannon
# Date: A while ago
# Last modified: 4-30-20
# Title: makeTaxonomyDatabase.pl
# Purpose: make a database of NCBI's taxonomy data
##############################


###############
### To do
# remove last file 
# check if each step completed properly
# check write permissions
# Write better -help section
# write out a log file
# md5 checks?
# *change the input files I use so I can get the full taxonomy and not just primary levels*

##############################
# Options
##############################


my $verbose;
my $help;
my $outDir = "\.";
my $dbName = "taxonomy.db";

# i = integer, s = string
GetOptions ("verbose"           => \$verbose,
            "help"              => \$help,
            "outDir=s"          => \$outDir,
            "databaseName=s"    => \$dbName
           
      )
 or pod2usage(0) && exit;

pod2usage(1) && exit if ($help);


##############################
# Global variables
##############################
my $counter = 1;
my $numLines;
my @columnLabels = ("tax_id", "tax_name", "species", "genus", 
		    "family", "order", "class", "phylum", 
		    "kingdom", "superkingdom");
my $columnCount = 10;
my @storageArray = ();

##############################
# Code
##############################

$outDir .= "/";
if (!-e $outDir and !-d $outDir) {
    system('mkdir', $outDir);
}

##############################
### Stuff
### More stuff

if($verbose) {
    print STDERR "Downloading new_taxdump.tar.gz from NCBI\n";
}

my $url = 'https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/new_taxdump/new_taxdump.tar.gz';
my $file = 'new_taxdump.tar.gz';
my $returnCode =  getstore($url, $outDir . $file);

if(is_error($returnCode)) {
    print "Download from NCBI failed with code: ", $returnCode, "\n"; 
    die;
}

if($verbose) {
    print STDERR "Extracting new_taxdump.tar.gz in $outDir\n";
}

my $tarCmd = "tar --overwrite -zxvf " . $outDir . $file . " -C " . $outDir;
print STDERR $tarCmd, "\n"; #die;
system("$tarCmd");

if($verbose) {
    print STDERR "Cleaning up unneccessary files in $outDir\n";
}

# get rid of the files I don't need to save space
my $cleanupCmd = "rm " .
                $outDir . "citations.dmp " .
                $outDir . "delnodes.dmp " .
                $outDir . "division.dmp " .
                $outDir . "fullnamelineage.dmp " .
                $outDir . "gencode.dmp " .
                $outDir . "host.dmp " .
                $outDir . "merged.dmp " .
                $outDir . "names.dmp " .
                $outDir . "new_taxdump.tar.gz " .
                $outDir . "nodes.dmp " .
                $outDir . "taxidlineage.dmp " .
                $outDir . "typematerial.dmp " .
                $outDir . "typeoftype.dmp";

system($cleanupCmd);

my $numLinesCmd = "wc -l " . $outDir . "rankedlineage.dmp";
$numLines = `$numLinesCmd`;
$numLines =~ s/ .+//;

##############################
### Stuff
### More stuff

# rankedlineage.dmp
# -----------------
# Select ancestor names for well-established taxonomic ranks (species, genus, family, order, class, phylum, kingdom, superkingdom) file fields:

        # tax_id                                -- node id
        # tax_name                              -- scientific name of the organism
        # species                               -- name of a species (coincide with organism name for species-level nodes)
	# genus					-- genus name when available
	# family				-- family name when available
	# order					-- order name when available
	# class					-- class name when available
	# phylum				-- phylum name when available
	# kingdom				-- kingdom name when available
	# superkingdom				-- superkingdom (domain) name when available



###########
### make database - from https://perlmaven.com/simple-database-access-using-perl-dbi-and-sql

if($verbose) {
    print STDERR "Creating taxonomy.db in $outDir\n";
}

if (-e $outDir . $dbName) {
    system('rm', $outDir . $dbName);
    print STDERR "Removing old database version\n";
}

my $dsn      = "dbi:SQLite:dbname=$outDir" . "$dbName";
my $user     = "";
my $password = "";

if($verbose) {
    print STDERR "Connecting to database\n";
}

my $dbh = DBI->connect($dsn, $user, $password, {
   PrintError       => 0,
   RaiseError       => 1,
   AutoCommit       => 1,
});

if($verbose) {
    print STDERR "Defining database structure\n";
}

my $sql = <<'END_SQL';
CREATE TABLE taxonomy (
  tax_id        VARCHAR(255) PRIMARY KEY,
  tax_name      VARCHAR(255),
  species       VARCHAR(255),
  genus         VARCHAR(255),
  family        VARCHAR(255),
  'order'       VARCHAR(255),
  class         VARCHAR(255),
  phylum        VARCHAR(255),
  kingdom       VARCHAR(255),
  superkingdom  VARCHAR(255)
)
END_SQL
 
$dbh->do($sql);

if($verbose) {
    print STDERR "Preparing input statement\n";
}

my $entryCount = 99;

my $prepStm = 'INSERT INTO taxonomy (tax_id, tax_name, species, genus, family, "order", class, phylum, kingdom, superkingdom) VALUES ' . join(",", ('(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)') x $entryCount);

my $sth = $dbh->prepare($prepStm) or die $dbh->errstr;

############
### Populate database

if($verbose){
    print STDERR "Begin!\n";
}

open my $inputFile, $outDir . "rankedlineage.dmp" or die "Could not open rankedlineage.dmp file\nWell, crap\n";
while (my $input = <$inputFile>){
    chomp $input;

    # cut off terminal \t| from end of each line
    $input =~ s/\t\|$//;

    # columns are delimited by \t|\t 
    my @array = split '\t\|\t', $input, -1;
    
    # put data into storageArray to be added to database later
    # Also put NA into empty fields
    for(my $i = 0; $i < scalar(@array); $i++) {
        if($array[$i] eq "") {
            $array[$i] = "NA";
        }
	push @storageArray, $array[$i];
    }

    # once enough entries are in the array, put them into the database all at once
    if(scalar(@storageArray) == $entryCount * $columnCount) {
	$sth->execute(@storageArray);

	# empty out storageArray
	@storageArray = ();
    }
    
    if($verbose){
	if($counter % 10000 == 0) {
            print STDERR $counter, " lines done, which is " , 
	    100 * ($counter / $numLines), "%                           \r";
        }
        $counter++;
    }
}

# put last entries into database
if(scalar(@storageArray > 0)) {
    $prepStm = 'INSERT INTO taxonomy (tax_id, tax_name, species, genus, family, "order", class, phylum, kingdom, superkingdom) VALUES ' .
                       join(",", ('(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)') x (scalar(@storageArray / $columnCount)));

    $sth = $dbh->prepare($prepStm) or die $dbh->errstr;

    $sth->execute(@storageArray);
}

$dbh->disconnect;

if($verbose) {
    print STDERR "Done!                               \n ";
}

##############################
# POD
##############################

#=pod
   
=head SYNOPSIS

Summary:    
   
    makeTaxonomyDb.pl - makes a database from NCBI's taxonomy data
   
Usage:

    perl makeTaxonomyDb.pl [options] --outDir [\.] --databaseName [taxonomy.db]


=head OPTIONS

Options:

    --verbose
    --help
    --outDir - directory to store database and intermediate files in
    --databaseName - name of database file 

=cut
