library(terra)
library(caTools)
library(R.utils)
library(BiocManager) 
library(rhdf5)

# jack tarricone
# september 29, 2021

#################################################################
#### produce code that goes into each year, then into each month 
#### untars, unzips each day
#### creates a header so it can be read in GDAL
#### creates data matrix
#### save as hdf5? just spit balling here
#################################################################

# Product code 
# 1025: Precipitation
# 1034: Snow water equivalent
# 1036: Snow depth
# 1038: Snow pack average temperature 
# 1039: Blowing snow sublimation
# 1044: Snow melt
# 1050: Snow pack sublimation

# path to all of the years, and list the years
masked <-file.path("/Volumes","G02158","masked") 
year_list <-list.files(masked)

year_list <-as.list(year_list[1])

extract_daily_swe <-function(list_of_years){
  
year_path <-file.path(masked, year_list) # create path to year

# list all all monthly folder in each year
month_list <-list.files(year_path)
month_path <-file.path(year_path, month_list[2]) # just for october test
}
for (j in 1:length(month_list)) {
  
  day_path <-file.path(month_path)
  day_list <-list.files(day_path, full.names = TRUE)
  
  # set files location by year (i think this should work using lapply for big function)
  saving_location <-file.path("/Users","jacktarricone","nres_proj_data","swe_data","reg_years",year_list)
  setwd(saving_location) # set as working direction
}
  
################################################################################################
# this forloop almost works for pulling out daily values but for some reason is skipping days
##############################    check on this ################################################
#######################################################################################
  
  for (i in 1:length(day_list)){
    
    # set files location by year (i think this should work using lapply for big function)
    saving_location <-file.path("/Users","jacktarricone","nres_proj_data","swe_data","reg_years", year_list)
    setwd(saving_location) # set as working direction
    
    untar(day_list[i], exdir = saving_location) # untar using i indexing here
    
    # list just the two SWE files (.dat and .txt) using swe indentifier 1034
    untarred_swe_files <-list.files(saving_location, pattern = "us_ssmv11034tS.*\\.gz$", full.names =  TRUE) 
    
    lapply(untarred_swe_files, gunzip) # unzip swe files list
    to_be_deleted <-list.files(saving_location, pattern = "*.gz|*.txt", full.names =  TRUE) # list all .gz zipped files
    file.remove(to_be_deleted) # delete them bc don't need
    
    # extract the name of the single day of SWE for header creation
    last_day <-as.integer(length(list.files(saving_location)))
    names_list <-list.files(saving_location, pattern = "*.dat")
    swe_name_raw <-names_list[length(names_list)]
    swe_name <- substr(names_list[length(names_list)],1,nchar(swe_name_raw)-4)
    
    # create envi header to reference binary SWE files
    header <-c("ENVI",
               "samples = 6935",
               "lines = 3351",
               "bands = 1",
               "header offset = 0",
               "file type = ENVI Standard",
               "data type = 2",
               "interleave = bsq",
               "byte order = 1")
    writeLines(header, paste0(swe_name,".hdr"))
  }




extract_daily_swe(year_list)






#### test to see our automatic header creation works
read_test <-list.files(saving_location, full.names = TRUE)

snodas_envi <-read.ENVI(read_test[1], read_test[2]) 
dim(snodas_envi) # check dims
snodas <-terra::rast(snodas_envi) # convert to rasters
values(snodas)[values(snodas) == -9999] = NA # change no data value to NA
crs(snodas) <-"+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs" # set proj
ext(snodas) <-c(-124.7337, -66.9421, 24.9504, 52.8754) # seet extent
plot(snodas) # test plot
writeRaster(snodas, "/Users/jacktarricone/nres_proj_data/snodas_test_oct1.tiff", overwrite=TRUE)





###### test swe
swe <-rast("/Users/jacktarricone/nres_proj_data/snodas/us_ssmv11034tS__T0001TTNATS2021010105HP001.dat")
swe
plot(swe)

# setting proj and cleaning data
values(swe)[values(swe) == -9999] = NA # change no data value to NA
crs(swe) <-"+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs" # set proj
ext(swe) <-c(-124.7337, -66.9421, 24.9504, 52.8754) # seet extent
plot(swe) # test plot
swe

test <-("/Users/jacktarricone/nres_proj_data/SNODAS_20180131.tar")
untar(test, exdir = "/Users/jacktarricone/nres_proj_data/SNODAS_20180131/")

test_list <-list.files("/Users/jacktarricone/nres_proj_data/SNODAS_20180131/", pattern = ".gz", full.names = TRUE)
lapply(test_list, gunzip)

gunzip("/Users/jacktarricone/nres_proj_data/SNODAS_20180101/us_ssmv01025SlL00T0024TTNATS2018010105DP001.dat.gz")


zip_list <-list.files("/Users/jacktarricone/nres_proj_data/", pattern = ".tar")
untarred_list <-lapply(zip_list, untar)

gz_list <-list.files("/Users/jacktarricone/nres_proj_data/", pattern = ".gz")
gz_untarred <-lapply(gz_list, function(x) untar(x, compressed = "gzip"))

header <-c("ENVI",
           "samples = 6935",
           "lines = 3351",
           "bands = 1",
           "header offset = 0",
           "file type = ENVI Standard",
           "data type = 2",
           "interleave = bsq",
           "byte order = 1",
           "map info = {Geographic Lat/Lon,",
           "1.000," ,
           "1.000,",
           "-106.566746880000011,",
           "36.121778400000004,",
           "0.00833,", 
           "0.00833,", 
           "WGS-84,", 
           "units=Degrees}")
writeLines(header, "testheader.hdr")
