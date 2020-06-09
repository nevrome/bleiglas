library(magrittr)

#### natural earth data ####

# land_outline
land_outline <- rnaturalearth::ne_download(
  scale = 50, type = 'land', category = 'physical'
) %>% sf::st_as_sf()



#### research area ####

# load manually crafted research area shape file, transform it to
# EPSG:102013 and store the result
research_area <- sf::st_read(
  "inst/workflow_example/research_area_shapefile/research_area.shp", quiet = TRUE
) %>%
  sf::st_transform(
    "+proj=aea +lat_1=43 +lat_2=62 +lat_0=30 +lon_0=10 +x_0=0 +y_0=0 +ellps=intl +units=m +no_defs"
  )
save(research_area, file = "inst/workflow_example/research_area.RData")



#### area ####

# load natural earth data land outline shape, crop it approximately to
# Europe, transform it to EPSG:102013, crop it to the research area and store the result
land_outline_small <- land_outline %>%
  sf::st_crop(xmin = -20, ymin = 35, xmax = 35, ymax = 65) %>%
  sf::st_transform(
    "+proj=aea +lat_1=43 +lat_2=62 +lat_0=30 +lon_0=10 +x_0=0 +y_0=0 +ellps=intl +units=m +no_defs"
  )



#### extended area ####

# crop land outline to enlarged bbox of research area
bb <- sf::st_bbox(research_area)
bb[1:2] <- bb[1:2] - 200000
bb[3:4] <- bb[3:4] + 200000
extended_research_area <- bb %>% sf::st_as_sfc()
extended_area <- sf::st_intersection(sf::st_buffer(land_outline_small, 0), extended_research_area)
save(extended_area, file = "inst/workflow_example/extended_area.RData")
