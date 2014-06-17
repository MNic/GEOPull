install.packages("XML")
install.packages("plyr")
install.packages("xlsx")
require(XML)
require(plyr)
require(xlsx)

#'Script is designed to make use of html querying functions built into the server side of
#'NCBIs Gene Expression Omnibus (GEO).  Here we use R to query the server for an xml type
#'file which R parses into a list of lists.  The lists are then reformatted and exported
#'as an xlsx file for linking/import into an MS Access database. 
#'
#'Inputs for this script are a csv file of GEO GSE Series IDs and a list of desired fields
#'to keep in the output.

#'Notes for downloading files directly:
#'In the url below acc=GSE####' is the series ID, 'targ=self' defines the report/dataset 
#'type from geo, 'form=xml' requests the MINimL format XML file.
#'
#'fn <- "http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE9960&targ=self&view=brief&form=xml"
#'data <- xmlParse(fn)
#'download.file(fn, destfile="tmp.txt")

###Test Data Pulls ###
#'These can be used,in place of the .csv import, to test changes in the loop iterating over a small number of IDs.
#'accid <- c("GSE28904","GSE29385", "GSE28991","GSE28988", "GSE28985", "GSE9960", "GSE12624")
#'accid <- data.frame(c("GSE16032", "GSE16032"))

#'Add all GEO Accession IDs of interest to accid field.  This will be iterated across to pull 
#'all data in the Forloop below.
#'geoidlist.csv contains a single column list of GEO series IDs with no header.

accid <- data.frame(read.csv("geoidlist.csv", header=FALSE))

#'Loop to iterate over GSE IDs in geoidlist.csv:
#'Queries GEO based on Series ID and returns an XML file of the 'self' report and
#'platform' report while also counting the number of samples available from each set.
#'These are displayed in the 'sampcount' column of the output.
#'Each loop adds a new line to the dataframe 'd' which can be exported as a csv after
#'completion of the loop.

d <- NULL   #Creates 'd' as an object in the environment
i<- 1       #i Loop: Adds the GSE Series ID of interest to the URL used to pull down the xml file.

for(i in 1:length(accid[,1])){
  
  #'self' data loop: uses xmlParse to split MINiML(xml) format for series metadata
  #'into lists and reformat to dataframe.
  
  url <- paste("http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=",accid[i,],"&targ=self&view=brief&form=xml",sep="")
  data <- xmlParse(url)
  xml_data <- xmlToList(data)
  out <- data.frame(xml_data)
  #'Each Sample has 1 'Sample.Accession.text' column.  Counting them gives us a sample count for each Series ID.
  sampcount <- length(names(out[, grep("Sample.Accession.text", colnames(out))])) 
  out1 <- out[, -grep("Sample", colnames(out))]
  dat <- out1[1,names(out1)]
  dat <- cbind(dat)
  
  #'platform' data loop: uses xmlTreeParse to split MINiML format for platform metadata
  #'into lists and reformat to dataframe.
  
  platurl <- paste("http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=",accid[i,],"&targ=gpl&view=brief&form=xml",sep="")
  data <- xmlTreeParse(platurl)
  xml_data1 <- xmlRoot(data)
  xmldat1 <- xmlSApply(xml_data1, function(x) xmlSApply(x, xmlValue))
  xmldat_df1<- data.frame(t(xmldat1), row.names=NULL)
  df <- do.call(rbind.data.frame, as.list(xmldat_df1$Platform$Platform))
  dft <- data.frame(t(df))
  dft <- dft[1,names(dft)]     #Parse returns 2 rows of data in some cases, this ensures we capture only 1 row per set.
  dat1 <- cbind(dat, dft, sampcount)
  d <- rbind.fill(data.frame(d[,names(d)]), data.frame(dat1[,names(dat1)]))
  
  i <- i+1
}

#'Create fieldkeep file:
#'File originally created using relevant fields from GSE9960
#'Due to variability in the fields available from various GEO datasets and our desire to
#'use the output data in a fixed structure database; we needed to limit output to the same
#'set of fields in the same order.

#fieldkeep <- names(d)[c(1:11,20,23:24,26:28,30:31,33:36,40, 42, 48:53, 55:57,65, 114:115)]
#write.csv(fieldkeep, file="fieldkeep.csv")

#Limit returned fields by desired fields listed in fieldkeep.csv
fieldkeep <- data.frame(read.csv("fieldkeep.csv"))
d1 <- d[,names(d) %in% fieldkeep[,"x"]]

#'Rename fields
#'Fields renamed to match Database.
names(d1)
newnames <- c("CFN", "CLN", "CEmail", "CLab", "CDept", "COrg", "CAddress", "CCity", "CState", "CZip", "CCtry", "DName",
              "DWebLink", "DEmail", "SeriesSubDate", "SeriesReleaseDate", "LastUpdate", "Title", "Accession", "PubmedID",
              "Summary", "OverallDesign", "Type", "SuppData", "SuppDataTxt1", "PTitle", "PAccession", "PTechnology",
              "PDistribution", "Organism", "Manufact", "Description", "PSuppdata", "SampleCount", "PSuppdata1", 
              "PSuppWebLink","PSuppWebLink1")
names(d1) <- newnames  

#Reorder fields to match MS Access database
reorder <- c("Accession", "Title", "Organism", "SampleCount", "SeriesSubDate", "SeriesReleaseDate", "LastUpdate", 
             "Summary", "OverallDesign", "Type", "SuppData", "SuppDataTxt1", "PTitle", "PAccession", "PTechnology",
             "PDistribution", "Manufact", "Description", "PSuppdata", "PSuppdata1", "PSuppWebLink", "PSuppWebLink1",
             "CFN", "CLN", "CEmail", "CLab", "CDept", "COrg", "CAddress", "CCity", "CState", "CZip", "CCtry", "DName",
             "DWebLink", "DEmail", "PubmedID")
d2 <- d1[,reorder]

#Remove extra carriage returns "\n" from all fields
d3 <- lapply(d2, function(x) gsub("\\n", "", x))
d4 <- lapply(d3, function (x) gsub("^\\s+|\\s+$", "", x))

#Output to Excel file named for Append query import into MS ACCESS DB
write.xlsx(x = d4, file = "pleasework_final_excel.xlsx", sheetName = "pleasework_final", row.names = FALSE)
