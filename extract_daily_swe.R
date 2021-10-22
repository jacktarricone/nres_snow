library(terra)
library(caTools)
library(R.utils)
library(BiocManager) 
library(rhdf5)
library(parallel)

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
masked <-file.path("/Volumes/G02158/masked") 
years_path_full <-list.files(masked[[1]], full.names = TRUE) # create path to each year
years <-list.files(masked) # just a years list for saving file path purposes

extract_daily_swe <-function(years_path_full){

  # list all all monthly folder path in each year
    months_path <-list.files(years_path_full, full.names = TRUE)
  
  # list of all days
    days_list <-list.files(months_path, full.names = TRUE)
  
  # set files location by year (i think this should work using lapply for big function)
    saving_location <-file.path("/Volumes","jack_t","nres_project","reg_years", years)
    setwd(saving_location) # set as working direction
  
  # now we can extract the files using the untar function
    system.time(lapply(days_list, untar, exdir = saving_location)) # untar the list
    
  # list just the two SWE files (.dat and .txt) using swe indentifier 1034
    untarred_swe_files <-list.files(saving_location, pattern = "us_ssmv11034tS.*\\.dat.gz$", full.names =  TRUE) 
    system.time(lapply(untarred_swe_files, gunzip)) # gunzip swe files list
  
  # since the files are unzipped and have extensions .dat, delete all other ones
    to_be_deleted <-list.files(saving_location, pattern = "*.gz|*.txt", full.names =  TRUE) # list all .gz zipped files
    file.remove(to_be_deleted) # delete them bc don't need
  
  # list our newly extracted SWE files
    swe_files <-list.files(saving_location)
    
    create_headers <-function(swe_file){
      
        # extract the name of the single day of SWE for header creation
            swe_name <- substr(swe_file,1,nchar(swe_file)-4)
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
    
  # apply create header funciton to list of SWE files
    lapply(swe_files, create_headers)
}

# test with parallelization on list of one year (03)
#years_path_full <-as.vector(years_path_full[[1]])
#years <-as.vector(years[[1]])

# apply to years list
system.time(lapply(years_path_full, extract_daily_swe))






#### test to see our automatic header creation works
path <-file.path("/Volumes","jack_t","nres_project","reg_years", "2003")
dat_files <-list.files(path, pattern = ".dat", full.names = TRUE) # list bin files
hdr_files <-list.files(path, pattern = ".hdr", full.names = TRUE)

mat_list <- vector(mode = "list", length = length(dat_files)) # create empty list to loop into
for (i in 1:length(dat_files)){
  mat_list[[i]] <-read.ENVI(dat_files[i], hdr_files[i]) 
}

rast_list <-lapply(mat_list, rast) # convert raw envi matrix to rasters
stack <-rast(rast_list) # stack rasters?
rm(mat_list, rast_list) # remove duplicate data

dim(stack) # check dims
values(stack)[values(stack) == -9999] = NA # change no data value to NA
crs(stack) <-"+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs" # set proj
ext(stack) <-c(-124.7337, -66.9421, 24.9504, 52.8754) # seet extent
plot(stack[[90]]) # test plot

writeRaster(stack, "/Users/jacktarricone/nres_proj_data/swe_stack_2003.tiff")

test <-rast("/Users/jacktarricone/nres_proj_data/swe_stack_2003.tiff")
plot(test[[30:40]])




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
