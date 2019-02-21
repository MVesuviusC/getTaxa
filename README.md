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



## To do:
Error handling is still a bit tricky. If the gi is unknown the program will error out. In the future I need to implement better handling of this and let the program continue, but output error messages containing bad gis. 

There are also issues when a gi has multiple annotated taxa. In this case, the first taxa is output and the rest are ignored. 

