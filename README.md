### _GEOPull_

##### Purpose
This R Script is designed to pull Series data from GEO in XML format and parse it for appending into an Access/SQL Database.  The intent is to create a relevant, searchable GEO subset locally to keep track of potential validation datasets and support data from other researchers.

The `XML` package and functions `xmlParse()` and `xmlToList()` are essential to parsing out the data of interest from NCBIs XML based storage structure.

##### The Process:

1. Update geoidlist.csv with GEO IDs of interest
2. Run R script to produce .xls file named appropriately and linked to the access database.
3. Run Make Table / Update Table Query in MS Access to populate database with new data retreived from GEO.

Access DB is setup with a field by field generic query.  The user is prompted for search criteria across the majority of relevant fields.  In all cases but one, a field left empty is considered a wildcard.  For sample number a value must be provided.  The Sample number prompt searches for all studies with at least the number of samples entered.  Even entering `0` is sufficient for the search.




