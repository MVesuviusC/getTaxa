# getTaxa.pl

The purpose of this script is to take in a list of gis or taxids and output matching taxonomy. 

The input is either a file with a single column of gis or a file with NCBI taxids. Providing taxids will be faster.

The output is a table of taxonomic data with the following columns: 
gi, kingdom, phylum, class, order, family, genus


## Usage

### Providing gis
perl getTaxa.pl --gis examples/inputGis.txt > examples/taxonomyFromGis.txt

#### If different taxonomic groups are desired, you can specify them using --ranks

perl getTaxa.pl --gis examples/inputGis.txt --ranks "superkingdom, kingdom, phylum, class, order, family, genus" > examples/specialTaxonomy.txt

### Providing taxids instead of gis

perl getTaxa.pl --taxids examples/inputTaxids.txt > examples/taxonomyFromTaxids.txt

# makeTaxonomyDb.pl

This script downloads the taxdump files from NCBI and makes a sql database that can be accessed by other progams. 

Downloading is fast, making the database is slower (~1-2 hrs)

## Usage
perl makeTaxonomyDb.pl --outDir outputDirectory --dbName taxonomy.db --verbose


# getTaxaLocal.pl
The point of this script is to do essentially the same thing as getTaxa.pl, but locally using the database created by makeTaxonomy.pl.

This script has additional functionality in that it can return a list of taxa that fall within a provided taxonomic group. For instance, given the genus "Plasmodium" the script will return taxa information for all taxa within this genus.

## Usage

### Get taxonomy info for taxids
perl getTaxaLocal.pl --taxids examples/inputTaxids.txt --dbName taxonomy.db 

### Get taxonomy info for provided taxonomic group
perl getTaxaLocal.pl --taxName Plasmodium,genus --dbName taxonomy.db

## To do:
Error handling is still a bit tricky. If the gi is unknown the program will error out. In the future I need to implement better handling of this and let the program continue, but output error messages containing bad gis. 

There are also issues when a gi has multiple annotated taxa. In this case, the first taxa is output and the rest are ignored. 

Need to update --help on makeTaxonomyDb.pl and getTaxaLocal.pl
