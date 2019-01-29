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
my $input;
my $ranks = "kingdom, phylum, class, order, family, genus";
my $queryNum = 100; 

# i = integer, s = string
GetOptions ("verbose"           => \$verbose,
            "help"              => \$help,
            "input=s"		=> \$input,
	    "ranks=s"           => \$ranks,
	    "queryNum=i"        => \$queryNum
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

print "gi\tspecies\t", join "\t", @classesToGet, "\n";

open INPUT1FILE, "$input" or die "Could not open input\nWell, crap\n";
while (my $gi = <INPUT1FILE>){
    chomp $gi;
    push @giList, $gi;
}
    
while(scalar(@giList) > 0) {
    my %gi2TaxHash;
    my %taxaHash; 

    my @gisToQuery;
    @gisToQuery = splice @giList, 0, $queryNum;

    if($verbose) {
	my $oldCounter = $counter; 
        $counter += scalar(@gisToQuery);
        print STDERR "Finding taxa for gis#", $oldCounter, "through ", $counter, "\n";
    }

    if($verbose) {
	print STDERR "Submitting gi to taxid query to NCBI\n";
    }
    my $gi2taxSearch = "GET \"" . $gi2tax . join("&id=", @gisToQuery) . "\"";
    my $gi2taxResponse = `$gi2taxSearch`;
    if($verbose) {
	print STDERR "Query retrieved\nParsing\n";
    }
    my @taxQuery; 
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
		push @taxQuery, $taxId;
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

    if($verbose) {
	print STDERR "Submitting taxonomy query to NCBI\n";
    }
    my $taxSearch = "GET \"" . $taxQuery . join("&id=", @taxQuery) . "\"";
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
    if($verbose) {
	print STDERR "Printing results\n";
    }
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

    perl getTaxa.pl [options] giList.txt 


=head OPTIONS

Options:

    --verbose
    --help
    --input
    --ranks
    --queryNum

=cut
