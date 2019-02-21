#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Long;
use Pod::Usage;
use XML::Simple;
use Data::Dumper;

##############################
# By Matt Cannon
# Date: 
# Last modified: 
# Title: .pl
# Purpose: 
##############################

##############################
# Options
##############################


my $verbose;
my $help;
my $gis;
my $taxids;
my $ranks = "kingdom, phylum, class, order, family, genus";
my $queryNum = 100;
my $debug;

# i = integer, s = string
GetOptions ("verbose"           => \$verbose,
            "help"              => \$help,
            "gis=s"		=> \$gis,
	    "taxids=s"          => \$taxids,
	    "ranks=s"           => \$ranks,
	    "queryNum=i"        => \$queryNum,
	    "debug"             => \$debug
      )
 or pod2usage(0) && exit;

pod2usage(1) && exit if ($help);


##############################
# Global variables
##############################
my $gi2tax = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?dbfrom=nuccore&db=taxonomy&idtype=acc&id=";
my $taxQuery = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=taxonomy&retmode=xml&id=";
my @classesToGet;
my @giList;
my @taxidList;
my %taxidHash;
my %gi2TaxHash;
my %taxaHash;
my $counter = 1;

##############################
# Code
##############################


##############################
### Stuff
### More stuff
$ranks =~ s/\s//g;
$ranks = lc($ranks);
@classesToGet = split(",", $ranks);

if($gis) {
    open my $giFH, "$gis" or die "Could not open gis input\nWell, crap\n";
    while (my $gi = <$giFH>){
	chomp $gi;
	push @giList, $gi;
    }
    print "gi\tspecies\t", join "\t", @classesToGet, "\n";
} elsif($taxids) {
    open my $taxaFH, "$taxids" or die "Could not open taxid input\nWell, crap\n";
    while (my $taxa = <$taxaFH>){
	chomp $taxa;
	push @taxidList, $taxa;
    }    
    print "taxid\tspecies\t", join "\t", @classesToGet, "\n";
} else {
    print STDERR "Must provide input to either --gis or --taxids\n\n";
    die;
}
    
while(scalar(@giList) > 0) {
    my @gisToQuery;
    @gisToQuery = splice @giList, 0, $queryNum;

    if($verbose) {
	my $oldCounter = $counter; 
        $counter += scalar(@gisToQuery);
        print STDERR "Finding taxids for gis#", $oldCounter, "through ", $counter - 1, "\n";
    }

    if($verbose) {
	print STDERR "Submitting gi to taxid query to NCBI\n";
    }

    my $gi2taxSearch = "GET \"" . $gi2tax . join("&id=", @gisToQuery) . "\"";
    my $gi2taxResponse = `$gi2taxSearch`;
    print STDERR $gi2taxSearch, "\n", if($debug);
    print STDERR $gi2taxResponse, "\n", if($debug);
    if($verbose) {
	print STDERR "Query retrieved\nParsing\n";
    }

    if($gi2taxResponse !~ /ERROR/) {
	my $giXML = XMLin($gi2taxResponse, forceArray => ['LinkSet', 'Link']);
	for(my $i = 0; $i < scalar(@{ $giXML->{LinkSet} }); $i++) {
	    my $giNum = $giXML->{LinkSet}[$i]{IdList}{Id};
	    my $taxId = $giXML->{LinkSet}[$i]{LinkSetDb}{Link}[0]{Id}; 
                # In cases where there are two taxids listed, keep the first. 
	        # This is rare and annoying when it happens. I may change the behaviour
	        # in the future to output all taxa info for each gi.
	    if(defined($taxId)) {
		$gi2TaxHash{$giNum} = $taxId;
		$taxidHash{$taxId} = 1;
	    } else {
		print STDERR "Gi# ", $giNum, " has no available taxonomy\n";
	    }
	}
    } else {
	print STDERR "Error in gi2tax id query\n";
	print STDERR $gi2taxSearch, "\n";
	print STDERR Dumper($gi2taxResponse), "\n";
	die;
    }
}

if($verbose) {
    print STDERR "Getting taxa info using taxids\n";
}

# Reset counter
$counter = 1;

# make @taxidList if gis were provided
if($gis) {
    @taxidList = keys(%taxidHash);
}

# Get taxonomy info using @taxidList
while(scalar(@taxidList) > 0) {
    print STDERR "\@taxidList contents: ", join("\t", @taxidList), "\n", if($debug);

    my @taxidsToQuery;
    @taxidsToQuery = splice @taxidList, 0, $queryNum;

    if($verbose) {
	my $oldCounter = $counter; 
        $counter += scalar(@taxidsToQuery);
        print STDERR "Finding taxonomy for taxids#", $oldCounter, "through ", $counter - 1, "\n";
    }

    if($verbose) {
	print STDERR "Submitting taxonomy query to NCBI\n";
    }

    my $taxSearch = "GET \"" . $taxQuery . join("&id=", @taxidsToQuery) . "\"";

    if($verbose) {
	print STDERR "Query retrieved\nParsing\n";
    }

    my $taxResponse = `$taxSearch`;
    if($taxResponse !~ /ERROR/) {
	my $taxaXML = XMLin($taxResponse, forceArray => ['Taxon']);
	#print Dumper($taxaXML); 
	#die;
	for(my $i = 0; $i < scalar(@{ $taxaXML->{Taxon} }); $i++) {
	    my $taxId = $taxaXML->{Taxon}[$i]{TaxId};
	    for(my $j = 0; $j < scalar(@{ $taxaXML->{Taxon}[$i]{LineageEx}{Taxon} }); $j++) {
		$taxaHash{$taxId}{species} = $taxaXML->{Taxon}[$i]{ScientificName};
		for my $rank (@classesToGet) {
		    if($rank eq $taxaXML->{Taxon}[$i]{LineageEx}{Taxon}[$j]{Rank}) {
			$taxaHash{$taxId}{$rank} = $taxaXML->{Taxon}[$i]{LineageEx}{Taxon}[$j]{ScientificName};
		    }
		}
	    }
	}
    } else {
	print STDERR "Error in taxa query\n";
	print $taxResponse, "\n";
	die;
    }

}


if($verbose) {
    print STDERR "Printing results\n";
}


if($gis) {
    for my $giNum (keys %gi2TaxHash) {
	my $taxId = $gi2TaxHash{$giNum};
	if(exists($taxaHash{$taxId})) {
	    print $giNum;
	    print "\t", $taxaHash{$taxId}{species};
	    for my $rank (@classesToGet) {
		if(exists($taxaHash{$taxId}{$rank})) {
		    print "\t", $taxaHash{$taxId}{$rank};
		} else {
		    print "\tNA";
		}
	    }
	    print "\n";
	}
    }
} else {
    for my $taxId (keys %taxaHash) {
	print $taxId;
	print "\t", $taxaHash{$taxId}{species};
	for my $rank (@classesToGet) {
	    if(exists($taxaHash{$taxId}{$rank})) {
		print "\t", $taxaHash{$taxId}{$rank};
	    } else {
		print "\tNA";
	    }
	}
	print "\n";
    }
}

exit;

##############################
# POD
##############################

#=pod
    
=head SYNOPSIS

Summary:    
    
    getTaxa.pl - get taxonomy information for provided GIs
    
Usage:

    perl getTaxa.pl [options] --input giList.txt 


=head OPTIONS

Options:

    --verbose
    --help
    --gis
       Single column of gis
    --taxids
       Single column of taxids
    --ranks
       List of ranks, separated by commas, all in a single quote
             for example: --ranks "superkingdom, kingdom, phylum, class, order, family, genus"
    --queryNum
       Number of gis to query at once. Probably don't need to change this

=cut
