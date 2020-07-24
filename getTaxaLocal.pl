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
my $taxName;
my $dbName = "taxonomy.db";

# i = integer, s = string
GetOptions ("verbose"           => \$verbose,
            "quiet"             => \$quiet,
            "help"              => \$help,
            "taxids=s"          => \$taxids,
            "taxName=s"         => \$taxName,
            "dbName=s"          => \$dbName
      )
 or pod2usage(0) && exit;

pod2usage(1) && exit if ($help);


##############################
# Global variables
##############################
my $sth;
my $query;

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


##############################
### Loop through taxids and get taxonomy data if taxids provided

if($taxids) { # if user provided taxids
    $query = 'SELECT tax_id, species_level, genus_level, family_level, order_level,
                class_level, phylum_level, kingdom_level, superkingdom_level, tax_name FROM
                taxonomy WHERE tax_id == ?';
    $sth = $dbh->prepare($query);

    open my $taxidFH, "$taxids" or die "Could not open taxid input\nWell, crap\n";

    print "taxid\tspecies\tsuperkingdom\tkingdom\tphylum\tclass\torder\tfamily\tgenus\ttax_name\n";

    while (my $taxid = <$taxidFH>){
	chomp $taxid;
	##### Put in some sort of check here to make sure the query looks like taxid
	
	my $output = parseSql($taxid);
    }
} elsif($taxName) { # if user provided taxonomy information
    my ($name, $level) = split ",", $taxName;
    $level = lc($level); # make sure level is all lowercase to match the database
    
    if($level eq "") { # make sure input is at least partly right
	print STDERR "\n--taxName option not correct. It should be in this format: Plasmodium,genus or \"Homo sapiens,species\"\n\n";
	die;
    }

    print "taxid\tspecies\tsuperkingdom\tkingdom\tphylum\tclass\torder\tfamily\tgenus\ttax_name\n";

    # lots of entries don't have any annotated species, but the species name is in tax_name >:-[
    # therefore, I need to check both the species column as well as the tax name column >:-(
    if($level eq "species") { 
	$query = 'SELECT tax_id, species_level, genus_level, family_level, order_level,
		    class_level, phylum_level, kingdom_level, superkingdom_level, tax_name FROM
		    taxonomy WHERE ' . $level . '_level == ? OR tax_name == ?';
	$sth = $dbh->prepare($query);
	parseSql($name, $name);
    } else {
	$query = 'SELECT tax_id, species_level, genus_level, family_level, order_level,
		    class_level, phylum_level, kingdom_level, superkingdom_level, tax_name FROM
		    taxonomy WHERE ' . $level . '_level == ?';
	$sth = $dbh->prepare($query);
	parseSql($name);
    }
}

$dbh->disconnect;

sub parseSql {
    my $searchTerm = shift;
    my $secondSearchTerm = shift; # this is used only for --taxName when level is species
    if(!defined($secondSearchTerm)) {
	$sth->execute($searchTerm);
    } else {
	$sth->execute($searchTerm, $secondSearchTerm);
    }

    my $retCount = 0;

    my ($taxid, $species, $superkingdom, $kingdom, $phylum, $class, $order, $family, $genus, $tax_name);

    while(my $row = $sth->fetchrow_hashref){
	$taxid        = "$row->{tax_id}";
	$species      = "$row->{species_level}";
	$genus        = "$row->{genus_level}";
	$family       = "$row->{family_level}";
	$order        = "$row->{order_level}";
	$class        = "$row->{class_level}";
	$phylum       = "$row->{phylum_level}";
	$kingdom      = "$row->{kingdom_level}";
	$superkingdom = "$row->{superkingdom_level}";
	$tax_name     = "$row->{tax_name}";
	
	$retCount++;
	
	if($species eq "NA") {
	    print STDERR "Species for \"", $searchTerm, "\", taxid:", $taxid, " is \"NA\". Substituting tax_name.\n" if(!$quiet);
	    $species = $tax_name;
	}
	
	print join("\t", $taxid, $species, $superkingdom, $kingdom, $phylum, $class, $order, $family, $genus, $tax_name), "\n";
    }
    if($retCount == 0) {
	print STDERR "Query ", $searchTerm, " not found\n" if(!$quiet);
    }
}


##############################
# POD
##############################

#=pod

=head SYNOPSIS

Summary:

    getTaxaLocal.pl - 

Usage:

    perl getTaxaLocal.pl [options] --taxids taxidList.txt --dbName taxonomy.db > outputTaxaInfo.txt
    
    or
    
    perl getTaxaLocal.pl [options] --taxName Plasmodium,genus --dbName taxonomy.db > outputTaxaInfo.txt


=head OPTIONS

Options:

    --verbose
    --help
    --taxids
    --taxName
    --dbName

=cut
