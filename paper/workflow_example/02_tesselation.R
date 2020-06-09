library(magrittr)

load("inst/workflow_example/dates_prepared.RData")
load("inst/workflow_example/research_area.RData")
load("inst/workflow_example/extended_area.RData")

vertices <- dates_prepared %>%
  dplyr::transmute(
    id = 1:nrow(.),
    x = round(x, 0),
    y = round(y, 0),
    z = calage_center * 1000,
    burial_type = burial_type,
    burial_construction = burial_construction
  )

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

vertices %<>% dplyr::filter(burial_type != "unknown")

#### tessellate and read result ####
bb <- sf::st_bbox(research_area)

poly_raw <- bleiglas::tessellate(
  vertices[,c("id", "x", "y", "z")],
  x_min = bb[1], x_max = bb[3], 
  y_min = bb[2], y_max = bb[4]
)
polygon_edges <- bleiglas::read_polygon_edges(poly_raw)

#### remove time overemphasis ####
polygon_edges %<>% dplyr::mutate(
  z.a = z.a / 1000,
  z.b = z.b / 1000
)

vertices %<>% dplyr::mutate(
  z = z / 1000
)

#### time cuts ####
cut_sufaces <- bleiglas::cut_polygons(
  polygon_edges,
  cuts = seq(-2200, -800, 200)
)

cut_surfaces_sf <- bleiglas::cut_polygons_to_sf(
  cut_sufaces,
  crs = "+proj=aea +lat_1=43 +lat_2=62 +lat_0=30 +lon_0=10 +x_0=0 +y_0=0 +ellps=intl +units=m +no_defs"
)

#### crop bleiglas by land area ####
cut_sufaces_cropped <- cut_surfaces_sf %>% sf::st_intersection(extended_area)

#### join bleiglas polygons and metainformation ####
cut_surfaces_info <- cut_sufaces_cropped %>%
  dplyr::left_join(
    vertices,
    by = "id"
  )

#### store results ####
save(vertices, polygon_edges, cut_surfaces_info, file = "inst/workflow_example/tesselation_calage_center_burial_type.RData")
