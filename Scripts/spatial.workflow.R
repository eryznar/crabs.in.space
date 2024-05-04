## NOTES -------------------------------------------------------------------------------
  # Spatial data types:
    # - Vector data: points, lines, polygons
    # - Raster data: spatially continuous data such as depth, temperature, etc.

  # Packages:
    # - sf: vector data; aka "simple features" such as points, lines, polygons; easier to convert to sf objects for plotting
    # - terra: raster data 

## Load crab-specific layers + AK regional layers, set coordinate ref systems (CRS), and load relevant packages --------------------
  source("./Scripts/load.spatialdata.R") 

## What layers are in the SAP geodatabase (gdb)?

  sf::st_layers(survey_gdb) 
  
## What layers/information is in the region_layers from akgfmaps?
  
  names(region_layers)
  
## Using crab vector data ------------------------------------------
  
  # Bristol Bay strata multipolygon
  BB_strata <- terra::vect(survey_gdb, layer = "BristolBaySurveyStrata") # can also use sf::st_read() to read layers in as sf objects
  
  ggplot()+
    theme_bw()+
    geom_sf(data= st_as_sf(BB_strata), fill = NA) 
  
  # EBS grid multipolygon
  EBS_grid <- terra::vect(survey_gdb, layer = "EBS_grid")
  
  ggplot()+
    theme_bw()+
    geom_sf(data= st_as_sf(EBS_grid), fill = NA)
  
  # Bristol Bay management area boundary (multiline string)
  BB_dist <- terra::vect(survey_gdb, layer = "BB_District")
  
  ggplot()+
    theme_bw()+
    geom_sf(data= st_as_sf(BB_dist), fill = NA)
  
  # Overlay different layers
  ggplot()+
    theme_bw()+
    geom_sf(data = st_as_sf(EBS_grid), fill = NA)+
    geom_sf(data= st_as_sf(BB_strata), fill = "lightblue")
  
  # Overlay with AK region layers from akfgmaps
  akland <- terra::vect(region_layers$akland)
  
  ggplot()+
    theme_bw()+
    geom_sf(data = st_as_sf(akland), fill = "lightgrey")+
    geom_sf(data = st_as_sf(EBS_grid), fill = NA)+
    geom_sf(data= st_as_sf(BB_strata), fill = "lightblue")
  
  # Specify plot boundary to region of interest and plot again
  plot.boundary.untrans <- data.frame(y = c(53, 64), 
                                      x = c(-174, -158)) # plot boundary unprojected
  
  plot.boundary <- plot.boundary.untrans %>% 
          sf::st_as_sf(coords = c(x = "x", y = "y"), crs = sf::st_crs(in.crs)) %>% # transform plot boundary df to sf class, set crs
          sf::st_transform(crs = map.crs) %>% # project boundary points to final mapping crs
          sf::st_coordinates() %>% # extract projected boundary coordinates
          as.data.frame() # transform coordinates back to a dataframe
         
  
  ggplot()+
    theme_bw()+
    geom_sf(data = st_as_sf(akland), fill = "lightgrey")+
    geom_sf(data = st_as_sf(EBS_grid), fill = NA)+
    geom_sf(data= st_as_sf(BB_strata), fill = "lightblue") +
    coord_sf(xlim = plot.boundary$X, # coord sf sets the plot boundary limits in a spatial context
             ylim = plot.boundary$Y) +
    ggplot2::scale_x_continuous(name = "", # can set the plotting breaks for lat and lon
                                breaks = seq(min(plot.boundary.untrans$x), max(plot.boundary.untrans$x), by = 5))+
    ggplot2::scale_y_continuous(name = "", 
                                breaks = seq(min(plot.boundary.untrans$y), max(plot.boundary.untrans$y), by = 2))
  

  ## Transforming vector objects to different crs
    BB_strata %>%
      terra::project("EPSG:6396") -> BB_strata2 # can use st_transform() for sf objects
    
    plot(BB_strata) # old crs
    plot(BB_strata2) # new crs
    
  ## Saving vector objects
    terra::writeVector(x = BB_strata, "./Data/BB_strata.shp")

## Using raster data ----------------------------------------
    
   # Loading spatial rasters
   cpue_rast <- terra::rast("./Data/SAP.avg.tif")
   sed_rast <- terra::rast("./Data/EBS_phi_1km.grd")
   
   # What is the extent of each raster?
   terra::ext(cpue_rast)
   terra::ext(sed_rast)
  
   # What is the resolution of each raster?
   terra::res(cpue_rast) # 1km
   terra::res(sed_rast) # 1km
   
   # What is the crs of each raster?
   terra::crs(cpue_rast) # none
   terra::crs(sed_rast)
   
   # Stacking rasters (to do so, rasters need to have equal extent, resolution, and crs)
   
    # 1) Project rasters to the same crs
    crs(cpue_rast) <- map.crs # set crs for this raster because it didn't have one already; 
                              # setting a crs does not project it to the new crs!!
    
    terra::project(cpue_rast, map.crs) -> cpue_rast2 # project to new crs 
    terra::project(sed_rast, map.crs) -> sed_rast2
    
    # 2) Set the extent of interest, crop rasters to the same extent
    rast_ext <- c(-1500000, -170000, 539823, 1600000)
    
    terra::crop(cpue_rast2, rast_ext) -> cpue_rast3
    terra::crop(sed_rast2, rast_ext) -> sed_rast3
    
    # 3) Resample rasters to align resolution (generally want to resample to coarsest resolution)
    terra::aggregate(cpue_rast3, fact = 5) -> cpue_rast4 # since both rasters are the same resolution, let's aggregate 
                                                  # this raster to a coarser resolution by a factor of 5; use disaggregate() for finer resolution
    
    terra::resample(sed_rast3, cpue_rast4) -> sed_rast4 # can use the same method as above, or can resample this raster to 
                                                 # match the resolution of another
    
    # 4) Stack rasters
    c(cpue_rast4, sed_rast4) -> rast_stack
    
    # 5) Masking rasters by vectors
    terra::project(BB_strata, map.crs) -> BB_strata2 # make sure vector matches crs of rasters
    
    terra::mask(rast_stack, BB_strata2) -> BB_rasters # mask raster stack by Bristol Bay strata vector
    
    names(BB_rasters) <- c("Average CPUE", "Sediment") # set raster names
    
    plot(BB_rasters)
  
  # Converting rasters to data frames
  cbind(crds(cpue_rast3), as.data.frame(cpue_rast3)) -> cpue_df
  
  # Plotting rasters with ggplot
  ggplot()+
    theme_bw()+
    geom_sf(data= st_as_sf(BB_strata2), fill = NA, linewidth = 1) +
    geom_sf(data = st_as_sf(EBS_grid), fill = NA)+
    geom_sf(data = st_as_sf(akland), fill = "lightgrey")+
    geom_tile(data = cpue_df, aes(x = x, y = y, fill = `SAP avg`))+
    scale_fill_viridis_c(option = "magma", name = "Average CPUE")+
    coord_sf(xlim = plot.boundary$X, 
             ylim = plot.boundary$Y) +
    ggplot2::scale_x_continuous(name = "",
                                breaks = seq(min(plot.boundary.untrans$x), max(plot.boundary.untrans$x), by = 5))+
    ggplot2::scale_y_continuous(name = "", 
                                breaks = seq(min(plot.boundary.untrans$y), max(plot.boundary.untrans$y), by = 2))
  
  # Adding labels to maps
  labs <- data.frame(lab = "Bristol Bay",
                     y = 58,
                     x = -166) %>% # Specify labels and map coordinates
          st_as_sf(coords = c(x = "x", y = "y"), crs = in.crs) %>% # transform to sf object
          st_transform(., map.crs) %>% # project to mapping crs
          cbind(st_coordinates(.), as.data.frame(.)) %>%
          as.data.frame() %>%
          dplyr::select(lab, X, Y)
  
  ggplot()+
    theme_bw()+
    geom_sf(data= st_as_sf(BB_strata2), fill = NA, linewidth = 1) +
    geom_sf(data = st_as_sf(EBS_grid), fill = NA)+
    geom_sf(data = st_as_sf(akland), fill = "lightgrey")+
    geom_tile(data = cpue_df, aes(x = x, y = y, fill = `SAP avg`))+
    scale_fill_viridis_c(option = "magma", name = "Average CPUE")+
    geom_shadowtext(labs, mapping = aes(X, Y, label = lab))+
    coord_sf(xlim = plot.boundary$X, 
             ylim = plot.boundary$Y) +
    ggplot2::scale_x_continuous(name = "",
                                breaks = seq(min(plot.boundary.untrans$x), max(plot.boundary.untrans$x), by = 5))+
    ggplot2::scale_y_continuous(name = "", 
                                breaks = seq(min(plot.boundary.untrans$y), max(plot.boundary.untrans$y), by = 2))
  