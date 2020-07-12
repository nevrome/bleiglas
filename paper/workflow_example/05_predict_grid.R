load(system.file("workflow_example", "dates_prepared.RData", package = "bleiglas", mustWork = T))

burial_type_data <- dates_prepared %>% dplyr::filter(burial_type != "unknown")

x <- lapply(1:15, function(age_resampling_run) {
  current_iteration <- data.table::data.table(
    id = 1:nrow(burial_type_data),
    x = burial_type_data$x,
    y = burial_type_data$y,
    z = sapply(burial_type_data$calage_sample, function(x){ x[age_resampling_run] }),
    burial_type = burial_type_data$burial_type
  )
  data.table::setkey(current_iteration, "x", "y", "z")
  unique( current_iteration ) 
})

all_iterations <- data.table::rbindlist(x)

prediction_grid <- expand.grid(
  x = seq(min(all_iterations$x), max(all_iterations$x), length.out = 100),
  y = seq(min(all_iterations$y), max(all_iterations$y), length.out = 100),
  z = seq(min(all_iterations$z), max(all_iterations$z), length.out = 10)
)

prediction_list <- bleiglas::predict_grid(x, prediction_grid, cl = 15)

prediction <- data.table::rbindlist(prediction_list)

proportion <- prediction %>% 
  dplyr::group_by(x, y, z) %>%
  dplyr::summarise(
    number_cremation = sum(burial_type == "cremation"),
    number_inhumation = sum(burial_type == "inhumation")
  ) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(
    cremation_inhumation_split = number_cremation/(number_cremation + number_inhumation)
  )

proportion_sf <- sf::st_as_sf(proportion, coords = c("x", "y"), crs = sf::st_crs("+proj=aea +lat_1=43 +lat_2=62 +lat_0=30 +lon_0=10 +x_0=0 +y_0=0 +ellps=intl +units=m +no_defs"))

load("inst/workflow_example/research_area.RData")
load("inst/workflow_example/extended_area.RData")

ex <- raster::extent(research_area)
xlimit <- c(ex[1], ex[2])
ylimit <- c(ex[3], ex[4])

library(ggplot2)

proportion %>% dplyr::filter(
  z == -1879
) %>%
  ggplot() +
  # geom_sf(
  #   data = extended_area,
  #   fill = "white", colour = "black", size = 0.4
  # ) +
  geom_raster(
    aes(x = x, y = y, fill = cremation_inhumation_split)
  )# +
  # geom_sf(
  #   data = extended_area,
  #   fill = NA, colour = "black", size = 0.4
  # ) +
  # geom_sf(
  #   data = research_area,
  #   fill = NA, colour = "black", size = 0.5
  # )
