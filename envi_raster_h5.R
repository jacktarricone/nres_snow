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
  
# testing
year <-years[[5]]

envi_to_hdf5 <-function(year){

# list .dat and .hdr files in each year, just 2004 to test
dat_files <-list.files(file.path("/Volumes","jack_t","nres_project","reg_years", year), 
                       pattern = ".dat", full.names = TRUE)
hdr_files <-list.files(file.path("/Volumes","jack_t","nres_project","reg_years", year), 
                       pattern = ".hdr", full.names = TRUE)

# create empty list to loop into
mat_list <- vector(mode = "list", length = length(dat_files))

# loop to read in data matrixes
system.time(for (i in 1:length(dat_files)){
  mat_list[[i]] <-read.ENVI(dat_files[i], hdr_files[i]) 
})

## define function to crop to western us
# 3351, 2488, 1 crops it to -104 lon or just east of denver
wu_crop <-function(x){x[,1:2488]}

# crop matrix list before making data cubes
system.time(mat_list <-lapply(mat_list, wu_crop))

# define dimensions 
nlines <-3351 # lat
nsamps <-2488 # lon orginally 6935

# use length of list to define to half chunks
# code was breaking when trying to convert whole list to array
# first_half <-as.integer(length(mat_list)/2)
  
# transform list of matrixes into large array aka datacube
system.time(swe_array <-array(as.numeric(unlist(mat_list)), dim=c(nlines, nsamps, length(mat_list))))
rm(mat_list)
system.time(swe_array[swe_array == -9999] <- NA) # change no data value to NA
system.time(swe_array <-swe_array/1000) # divide to get units meters

############################
##### save to h5 file ######
############################

# setwd , change for function
setwd(file.path("/Volumes","jack_t","nres_project","hdf5_reg_years")) 

hdf_file_name <-paste0("swe_daily_",year,".h5")

h5createFile(hdf_file_name) # create empty .h5 file

# create data set with proper info, set "chunk"
# level is compression amount 0 - 9, 9 is most compressed but slowest to read in
h5createDataset(file = paste0("swe_daily_",year,".h5"), dataset = "swe",
                dims = c(nlines, nsamps, length(dat_files)), level = 5, chunk = c(nlines, nsamps, length(dat_files)),
                storage.mode = "double")

# view the structure of the h5 we've created
h5ls(hdf_file_name)

# write data the the hdf5 file we made
h5write(swe_array, hdf_file_name,"swe")
rm(swe_array)

}



# info for converting to rasters

# ext(swe_stack) <-c(-124.7337, -104.0004, 24.9504, 52.8754)
# crs(swe_stack) <-"+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs" # set proj


#########################################
##### test read back in the new h5 ######
#########################################

# set path and file name for hdf5 SWE file
hdf_file <-list.files(full.names = TRUE)
h5ls(hdf_file[2]) #list contains 3 groups. lat, long, and SWE !
h5readAttributes(hdf_file[2], name = "swe") 

system.time(snodas <- h5read(hdf_file[2], "/swe"))#read in SWE group
class(snodas) #inspect 
dim(snodas) #dimensions

max_swe <-as.matrix(apply(snodas, c(1,2), max))
max_swe <-rast(max_swe)
ext(max_swe) <-c(-124.7337, -104.0004, 24.9504, 52.8754)
crs(max_swe) <-"+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs" # set proj
plot(max_swe)
writeRaster(max_swe, "/Users/jacktarricone/nres_proj_data/max_swe_2004.tiff")






###### old raster code

ext(swe_stack) <-c(-124.7337, -104.0004, 24.9504, 52.8754)
crs(swe_stack) <-"+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs" # set proj
plot(swe_stack)

ext(swe_stack) <-c(-124.7337, -66.9421, 24.9504, 52.8754) # set extent

# crop at -104 lon, a bit east of denver
crop_ext <-c(-124.7337, -104.0004, 24.9504, 52.8754) # set extent
swe_crop <- crop(swe_stack, crop_ext)	
plot(swe_crop[[80]])
writeRaster(swe_crop[[92]], "/Users/jacktarricone/nres_proj_data/crop_test.tiff")
swe_crop_array <-as.array(swe_crop)


# read in 1 days SWE data which is an array, or stack of matrixes
system.time(swe_03 <- h5read(hdf_file, "/swe")) #read in SWE group
class(swe_03) #inspect 
dim(swe_03) #dimensions
test <-rast(swe_03[,,92])
crs(test) <-"+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs" # set proj
ext(test) <-c(-124.7337, -104.0004, 24.9504, 52.8754) # set extent
plot(test)

writeRaster(test, "/Users/jacktarricone/nres_proj_data/h5_test.tiff")





stack <-rast(swe_array[,,92])
dim(stack) # check dims
# values(stack)[values(stack) == -9999] = NA # change no data value to NA
crs(stack) <-"+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs" # set proj
ext(stack) <-c(-124.7337, -66.9421, 24.9504, 52.8754) # seet extent
plot(stack) # test plot

writeRaster(stack, "/Users/jacktarricone/nres_proj_data/test_swe.tiff")

test <-rast("/Users/jacktarricone/nres_proj_data/swe_stack_2003.tiff")
plot(test[[30:40]])



