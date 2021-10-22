library(terra)
library(caTools)
library(R.utils)
library(BiocManager) 
library(rhdf5)

# jack tarricone
# october 22, 2021

## transforming raw ENVI files into formatted rasterstacks
## then to WY?
## then to hdf5?


# list years 2003 - 2021 paths for downloaded data
envi_years <-file.path("/Volumes","jack_t","nres_project","reg_years")
years_path <-list.files(envi_years, full.names = TRUE) # create path to each year
years <-list.files(envi_years) # just a years list for saving file path purposes

# list .dat and .hdr files in each year, just 2004 to test
dat_files <-list.files(years_path[2], pattern = ".dat", full.names = TRUE)
hdr_files <-list.files(years_path[2], pattern = ".hdr", full.names = TRUE)

mat_list <- vector(mode = "list", length = length(dat_files)) # create empty list to loop into

# loop to read in data matrixes
system.time(for (i in 1:length(dat_files)){
  mat_list[[i]] <-read.ENVI(dat_files[i], hdr_files[i]) 
})

# transform list of matrixes into large array aka datacube
system.time(swe_array <-array(as.numeric(unlist(mat_list)), dim=c(3351, 6935, length(mat_list))))

setwd(file.path("/Volumes","jack_t","nres_project","reg_years","annual_h5")) # setwd , change for function

h5createFile("swe_daily_2004.h5")
h5createGroup("swe_daily_2004.h5", "swe")

# view the structure of the h5 we've created
h5ls("swe_daily_2004.h5")

attr(swe_array, "swe") <- "meters"

sessionInfo()
h5write(swe_array, "swe_daily_2004.h5","swe")


# rast_list <-lapply(mat_list, rast) # convert raw envi matrix to rasters
# rm(mat_list) # remove mat list
# swe_stack <-rast(rast_list) # stack rasters?
# rm(rast_list) # remove rast list

dim(swe_stack) # check dims
values(swe_stack)[values(swe_stack) == -9999] = NA # change no data value to NA
crs(stack) <-"+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs" # set proj
ext(stack) <-c(-124.7337, -66.9421, 24.9504, 52.8754) # seet extent
plot(stack[[90]]) # test plot

writeRaster(stack, "/Users/jacktarricone/nres_proj_data/swe_stack_2003.tiff")

test <-rast("/Users/jacktarricone/nres_proj_data/swe_stack_2003.tiff")
plot(test[[30:40]])



