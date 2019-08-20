#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Long;
use Pod::Usage;
use LWP::Simple;
use DBI;

##############################
# By Matt Cannon
# Date:
# Last modified:
# Title: .pl
# Purpose:
##############################


###############
### To do
# remove last file 
# check if each step completed properly
# check write permissions
# Write better -help section
# write out a log file
# md5 checks?


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

my $url = 'ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/new_taxdump/new_taxdump.tar.gz';
my $file = 'new_taxdump.tar.gz';
getstore($url, $outDir . $file);

if($verbose) {
    print STDERR "Extracting new_taxdump.tar.gz in $outDir\n";
}

my $tarCmd = "tar -zxvf --overwrite" . $outDir . $file . " -C " . $outDir;
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
}

my $dsn      = "dbi:SQLite:dbname=$outDir" . "$dbName";
my $user     = "";
my $password = "";
my $dbh = DBI->connect($dsn, $user, $password, {
   PrintError       => 0,
   RaiseError       => 1,
   AutoCommit       => 1,
});


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

############
### Populate database

open my $inputFile, $outDir . "rankedlineage.dmp" or die "Could not open rankedlineage.dmp file\nWell, crap\n";
while (my $input = <$inputFile>){
    chomp $input;
    $input =~ s/\t\|$//;
    my @array = split '\t\|\t', $input, -1;

    for(my $i = 0; $i < scalar(@array); $i++) {
        if($array[$i] eq "") {
            $array[$i] = "NA";
        }
    }

    $dbh->do('INSERT INTO taxonomy (tax_id, tax_name, species, genus, 
        family, "order", class, phylum, kingdom, 
        superkingdom) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      undef,
      @array);
    if($verbose){
        if($counter % 1000 == 0) {
            print STDERR $counter, " lines done, which is " , 
                        100 * ($counter / $numLines), "%                           \r";
        }
        $counter++;
    }
}

$dbh->disconnect;

##############################
# POD
##############################

#=pod
   
=head SYNOPSIS

Summary:    
   
    makeTaxonomyDb.pl - 
   
Usage:

    perl makeTaxonomyDb.pl [options]


=head OPTIONS

Options:

    --verbose
    --help

=cut
