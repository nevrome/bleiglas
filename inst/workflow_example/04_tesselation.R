library(magrittr)

load("inst/workflow_example/dates_prepared.RData")
load("inst/workflow_example/research_area.RData")
load("inst/workflow_example/extended_area.RData")
load("inst/workflow_example/epsg102013.RData")

#### prepare vertices for tessellation from C14 data ####

vertices <- dates_prepared %>%
  dplyr::transmute(
    id = 1:nrow(.),
    x = round(x, 0),
    y = round(y, 0),
    z = calage_center,
    burial_type = burial_type,
    burial_construction = burial_construction
  )

#### scaling age/z value up ####

vertices$z <- vertices$z * 1000

#### make observations unique ####

dec <- function(x, a, b) {
  if (all(c(a, b) %in% x)) { return("unknown") } 
  else if (a %in% x) { return(a) } 
  else if (b %in% x) { return(b) }
  else { return("unknown") }
}

vertices %<>%
  dplyr::group_by(x, y, z) %>%
  dplyr::summarise(
    id = dplyr::first(id),
    burial_type = dec(burial_type, "cremation", "inhumation"),
    burial_construction = dec(burial_construction, "mound", "flat")
  ) %>% dplyr::ungroup()

# reduce selection to dates with information about burial type
vertices %<>% dplyr::filter(burial_type != "unknown")

#### tessellate and read result ####

bb <- sf::st_bbox(research_area)

poly_raw <- bleiglas::tessellate(
  vertices[,c("id", "x", "y", "z")],
  x_min = bb[1], x_max = bb[3], 
  y_min = bb[2], y_max = bb[4]
)
polygon_edges <- bleiglas::read_polygon_edges(poly_raw)

#### scale age/z down again ####

polygon_edges %<>% dplyr::mutate(
  z.a = z.a / 1000,
  z.b = z.b / 1000
)

vertices %<>% dplyr::mutate(
  z = z / 1000
)

#### cut tessellation volume ####

cut_surfaces <- bleiglas::cut_polygons(
  polygon_edges,
  cuts = seq(-2200, -800, 200)
)

#### transform resulting 2D polygon surfaces to sf format ####

cut_surfaces_sf <- bleiglas::cut_polygons_to_sf(
  cut_surfaces,
  crs = epsg102013
)

#### crop 2D polygon surfaces by land area and research area ####

cut_surfaces_cropped <- cut_surfaces_sf %>% 
  sf::st_intersection(extended_area) %>%
  sf::st_intersection(research_area)

#### join 2D polygons and vertex point wise context information ####

cut_surfaces_info <- cut_surfaces_cropped %>%
  dplyr::left_join(
    vertices,
    by = "id"
  )

save(
  vertices, polygon_edges, cut_surfaces, cut_surfaces_info, 
  file = "inst/workflow_example/tesselation_calage_center_burial_type.RData"
)
