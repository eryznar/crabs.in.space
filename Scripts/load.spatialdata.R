### LOAD PACKAGES -----------------------------------------------------------------------------------------
library(sf)
library(tidyverse)
library(raster)
library(terra)
library(lubridate)
library(akgfmaps)
library(shadowtext)

#devtools::install_github("afsc-gap-products/akgfmaps", build_vignettes = FALSE)


## SET COORDINATE REFERENCE SYSTEMS (CRS) --------------------------------------

in.crs <- "+proj=longlat +datum=NAD83" # sometimes will need to specify an input CRS for some spatial data. This CRS is in lat/lon
map.crs <- "EPSG:3338" # final crs for mapping/plotting etc. This CRS is good for Alaska ("Alaska Albers")

## LOAD SHELLFISH ASSESSMENT PROGRAM GEODATABASE -------------------------------

survey_gdb <- "Y:/KOD_Survey/EBS Shelf/Spatial crab/SAP_layers.gdb" # ".gdb" is a geodatabase

## LOAD ALASKA REGION LAYERS (FROM AKGFMAPS) -----------------------------------

region_layers <- akgfmaps::get_base_layers(select.region = "bs.south", set.crs=map.crs) #
