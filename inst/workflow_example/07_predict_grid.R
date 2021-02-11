library(magrittr)
library(ggplot2)

load("inst/workflow_example/dates_prepared.RData")
load("inst/workflow_example/research_area.RData")
load("inst/workflow_example/extended_area.RData")
load("inst/workflow_example/epsg102013.RData")

#### reduce selection to dates with known burial type ####

burial_type_data <- dates_prepared %>% dplyr::filter(burial_type != "unknown")

#### prepare 30 temporal resampling vertex collection iterations ####

iterations <- lapply(1:30, function(age_resampling_run) {
  current_iteration <- data.table::data.table(
    id = 1:nrow(burial_type_data),
    x = burial_type_data$x,
    y = burial_type_data$y,
    z = sapply(burial_type_data$calage_sample, function(x){ 
      x[age_resampling_run] }
    ) * 1000,
    burial_type = burial_type_data$burial_type
  )
  # make sure that the observation selection is unique
  unique( current_iteration[!duplicated(current_iteration[,c("x", "y", "z")])] ) 
})

#### prepare prediction grid ####

bb <- sf::st_bbox(research_area)
prediction_grid <- expand.grid(
  x = seq(bb[1], bb[3], length.out = 100),
  y = seq(bb[2], bb[4], length.out = 100),
  z = seq(-2200, -800, 200) * 1000
)

#### run grid prediction ####

prediction_list <- bleiglas::predict_grid(iterations, prediction_grid, cl = 15)
prediction <- data.table::rbindlist(prediction_list)

#### calculate value burial type proportion per prediction grid point ####

proportion <- prediction %>% 
  dplyr::mutate(
    z = z / 1000
  ) %>%
  dplyr::group_by(x, y, z) %>%
  dplyr::summarise(
    number_cremation = sum(burial_type == "cremation"),
    number_inhumation = sum(burial_type == "inhumation")
  ) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(
    cremation_inhumation_split = 
      number_cremation/(number_cremation + number_inhumation)
  )

#### crop grid points to land area in research area ####

proportion_cropped <- proportion %>%
  sf::st_as_sf(
    coords = c("x", "y"), 
    crs = sf::st_crs(epsg102013),
    remove = FALSE
  ) %>% 
  sf::st_intersection(extended_area) %>%
  sf::st_intersection(research_area) %>%
  sf::st_drop_geometry()

#### plot ####

ex <- raster::extent(research_area)
xlimit <- c(ex[1], ex[2])
ylimit <- c(ex[3], ex[4])

p <- proportion_cropped %>% 
  ggplot() +
  geom_sf(
    data = extended_area,
    fill = "white", colour = "black", size = 0.4
  ) +
  geom_tile(
    aes(x = x, y = y, fill = cremation_inhumation_split)
  ) +
  geom_sf(
    data = extended_area,
    fill = NA, colour = "black", size = 0.4
  ) +
  geom_sf(
    data = research_area,
    fill = NA, colour = "black", size = 0.5
  ) +
  scale_fill_gradient(low = "#0072B2", high = "#D55E00") +
  facet_wrap(~z, nrow = 2) +
  coord_sf(
    xlim = xlimit, ylim = ylimit,
    crs = sf::st_crs(epsg102013)
  ) +
  guides(
    fill = guide_colorbar(
      title = "Burial type proportion: inhumation <-> cremation    ", 
      barwidth = 20
    )
  ) +
  theme_bw() +
  theme(
    plot.title = element_text(size = 30, face = "bold"),
    legend.position = "bottom",
    legend.title = element_text(size = 20, face = "bold"),
    axis.title = element_blank(),
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    legend.text = element_text(size = 20),
    strip.text.x = element_text(size = 20),
    panel.background = element_rect(fill = "#BFD5E3")
  ) 

#### save plot ####
  
p %>% 
  ggsave(
    "inst/workflow_example/07_prediction_grid_plot.jpeg",
    plot = .,
    device = "jpeg",
    scale = 1,
    dpi = 72,
    width = 550, height = 280, units = "mm",
    limitsize = F
  )

p %>% 
  ggsave(
    "paper/07_prediction_grid_plot.jpeg",
    plot = .,
    device = "jpeg",
    scale = 1,
    dpi = 300,
    width = 550, height = 280, units = "mm",
    limitsize = F
  )

#### didactic output for vignette ####

prediction_grid_example <- prediction[1:10,]

save(
  prediction_grid_example, 
  file = "inst/workflow_example/prediction_grid_example.RData"
)
