#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Long;
use Pod::Usage;
use LWP::Simple;
use DBI;

##############################
# By Matt Cannon
# Date: 6-27-19
# Last modified: 8-22-19
# Title: getTaxaLocal.pl
# Purpose: get taxonomy data for taxids from local database
##############################

##############################
# Options
##############################

my $verbose;
my $quiet;
my $help;
my $taxids;
my $dbName = "taxonomy.db";

# i = integer, s = string
GetOptions ("verbose"           => \$verbose,
	    "quiet"             => \$quiet,
            "help"              => \$help,
	    "taxids=s"          => \$taxids,
	    "dbName=s"          => \$dbName
      )
 or pod2usage(0) && exit;

pod2usage(1) && exit if ($help);


##############################
# Global variables
##############################

##############################
# Code
##############################

##############################
### Open link to database and create query
my $dsn      = "dbi:SQLite:dbname=$dbName";
my $user     = "";
my $password = "";
my $dbh = DBI->connect($dsn, $user, $password, {
   PrintError       => 1,
   RaiseError       => 1,
   AutoCommit       => 1,
});

my $query = 'SELECT species, genus, family, "order",
                class, phylum, kingdom, superkingdom, tax_name FROM
                taxonomy WHERE tax_id == ?';
my $sth = $dbh->prepare($query);

##############################
### Loop through taxids and get taxonomy data

open my $taxidFH, "$taxids" or die "Could not open taxid input\nWell, crap\n";
while (my $taxid = <$taxidFH>){
    chomp $taxid;
    ##### Put in some sort of check here to make sure the query looks like taxid
    
    $sth->execute($taxid);

    my ($species, $superkingdom, $kingdom, $phylum, $class, $order, $family, $genus, $tax_name);
    while(my $row = $sth->fetchrow_hashref){
        $species      = "$row->{species}";
        $genus        = "$row->{genus}";
        $family       = "$row->{family}";
        $order        = "$row->{order}";
        $class        = "$row->{class}";
        $phylum       = "$row->{phylum}";
        $kingdom      = "$row->{kingdom}";
        $superkingdom = "$row->{superkingdom}";
        $tax_name     = "$row->{tax_name}";
    }
    if(defined($tax_name)) {
	print join("\t", $taxid, $species, $superkingdom, $kingdom, $phylum, $class, $order, $family, $genus, $tax_name), "\n";
    } else {
	print STDERR "taxid ", $taxid, " not found\n";
    }
}


$dbh->disconnect;

##############################
# POD
##############################

#=pod

=head SYNOPSIS

Summary:

    getTaxaLocal.pl - 

Usage:

    perl getTaxaLocal.pl [options] --taxids taxidList.txt --dbName taxonomy.db > outputTaxaInfo.txt


=head OPTIONS

Options:

    --verbose
    --help
    --taxids
    --dbName

=cut
