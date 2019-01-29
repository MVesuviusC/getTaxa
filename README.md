# getTaxa.pl

The purpose of this script is to take in a list of gis and output matching taxonomy. 

The input is a file with a single column of gis. 

The output is a table of taxonomic data with the following columns: 
gi, kingdom, phylum, class, order, family, genus


## Usage

perl getTaxa.pl --input examples/inputGis.txt > examples/taxonomy.txt

### If different taxonomic groups are wanted, you can specify them using --ranks

perl getTaxa.pl --input examples/inputGis.txt --ranks "superkingdom, kingdom, phylum, class, order, family, genus" > examples/specialTaxonomy.txt



## To do:
Error handling is still a bit tricky. If the gi is unknown the program will error out. In the future I need to implement better handling of this and let the program continue, but output error messages containing bad gis. 

There are also issues when a gi has multiple annotated taxa. In this case, the first taxa is output and the rest are ignored. 

