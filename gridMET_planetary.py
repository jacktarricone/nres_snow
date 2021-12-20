#!/usr/bin/env python
# coding: utf-8

# In[ ]:


## Accessing gridMET data with the Planetary Computer STAC API

gridMET is a dataset of daily high-spatial resolution (~4-km, 1/24th degree) surface meteorological data covering the contiguous US from 1979. These data can provide important inputs for ecological, agricultural, and hydrological models.


## Data Access

gridMET is available under the [`gridmet` collection](http://planetarycomputer.microsoft.com/api/stac/v1/collections/gridmet) in the STAC API. You can open that URL directly with `pystac`, or browse to the collection from the main STAC endpoint with pystac-client. Either way, the URL to the Zarr store in Blob Storage is in the `zarr-abfs` asset.


# In[1]:


import pystac_client
import planetary_computer

catalog = pystac_client.Client.open(
    "https://planetarycomputer.microsoft.com/api/stac/v1"
)
gridmet = catalog.get_collection("gridmet")
asset = planetary_computer.sign(gridmet.assets["zarr-abfs"])
asset


# Now this asset can be opened with fsspec and xarray.

# In[6]:


import fsspec
import xarray as xr

store = fsspec.get_mapper(asset.href, **asset.extra_fields["xarray:storage_options"])
ds = xr.open_zarr(store, **asset.extra_fields["xarray:open_kwargs"])

print("nbytes in MB:", ds.nbytes / (1024*1024))

ds = ds.sel(time=slice("2003-10-01", "2020-09-30"))
ds
print("nbytes in MB:", ds.nbytes / (1024*1024))
print(ds)


# In[73]:


ds_mean = ds.resample(time='QS-DEC', skipna = True).mean()
ds_mean.time

ds_sum = ds.resample(time='QS-DEC', skipna = True).sum()
ds_sum.time


# In[52]:


ssns = ds_sum.time.dt.season
yrs = ds_sum.time.dt.year

ds_sum_ex = ds_sum.expand_dims({'season':ssns, 'year':yrs})
ds_sum_ex.time

ds_sum_DJF = ds_sum.isel(time=(ds_sum.time.dt.season == 'DJF'))
ds_sum_MAM = ds_sum.isel(time=(ds_sum.time.dt.season == 'MAM'))
ds_mean_DJF = ds_mean.isel(time=(ds_mean.time.dt.season == 'DJF'))
ds_mean_MAM = ds_mean.isel(time=(ds_mean.time.dt.season == 'MAM'))

# In[75]:


ds_mean_DJF.to_netcdf("gridmet_mean_DJF.nc")
ds_mean_MAM.to_netcdf("gridmet_mean_MAM.nc")
ds_sum_DJF.to_netcdf("gridmet_sum_DJF.nc")
ds_sum_MAM.to_netcdf("gridmet_sum_MAM.nc")

