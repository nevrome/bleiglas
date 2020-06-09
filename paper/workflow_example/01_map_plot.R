library(magrittr)
library(ggplot2)

load("analysis/data/tmp_data/dates_prepared.RData")
load("analysis/data/tmp_data/research_area.RData")
load("analysis/data/tmp_data/extended_area.RData")

dates_prepared_unnested <- dates_prepared %>% 
  dplyr::select(labnr, calage_density_distribution, burial_type, burial_construction, geometry) %>%
  tidyr::unnest("calage_density_distribution")

dates_slices <- dates_prepared_unnested <- dates_prepared_unnested %>%
  dplyr::filter(
    age %in% seq(-2200, -800, by = 200)
  ) %>%
  dplyr::mutate(
    age_slice = factor(age, levels = seq(-2200, -800, by = 200))
  )

dates_slices_geo <- dates_slices %>% sf::st_as_sf()

ex <- raster::extent(research_area)
xlimit <- c(ex[1], ex[2])
ylimit <- c(ex[3], ex[4])

hu <- ggplot() +
  geom_sf(
    data = extended_area,
    fill = "white", colour = "black", size = 0.4
  ) +
  geom_sf(
    data = research_area,
    fill = NA, colour = "black", size = 0.5
  ) +
  geom_sf(
    data = dates_slices_geo,
    mapping = aes(
      color = burial_type,
      shape = burial_construction,
      size = burial_construction,
      alpha = norm_dens
    ),
    show.legend = "point"
  ) +
  theme_bw() +
  coord_sf(
    xlim = xlimit, ylim = ylimit,
    crs = sf::st_crs("+proj=aea +lat_1=43 +lat_2=62 +lat_0=30 +lon_0=10 +x_0=0 +y_0=0 +ellps=intl +units=m +no_defs")
  ) + 
  scale_shape_manual(
    values = c(
      "flat" = "\u268A",
      "mound" = "\u25E0",
      "unknown" = "\u2715"
    )
  ) +
  scale_size_manual(
    values = c(
      "flat" = 10,
      "mound" = 10,
      "unknown" = 5
    )
  ) +
  scale_color_manual(
    values = c(
      "cremation" = "#D55E00",
      "inhumation" = "#0072B2",
      "mound" = "#CC79A7",
      "flat" = "#009E73",
      "unknown" = "darkgrey"
    )
  ) +
  theme(
    plot.title = element_text(size = 30, face = "bold"),
    legend.position = "bottom",
    legend.title = element_text(size = 20, face = "bold"),
    axis.title = element_blank(),
    axis.text = element_blank(),
    legend.text = element_text(size = 20),
    panel.grid.major = element_line(colour = "grey", size = 0.3),
    strip.text.x = element_text(size = 20)
  ) +
  guides(
    color = guide_legend(title = "Burial type", override.aes = list(size = 10), nrow = 2, byrow = TRUE, order = 1),
    shape = guide_legend(title = "Burial construction", override.aes = list(size = 10), nrow = 2, byrow = TRUE, order = 2),
    size = FALSE,
    alpha = guide_legend(title = "Calibration density", override.aes = list(size = 10, shape = 15), nrow = 2, byrow = TRUE, order = 3)
  ) +
  facet_wrap(
    nrow = 2,
    ~age_slice
  )

hu %>%
  ggsave(
    "analysis/figures/map_timeslices.jpeg",
    plot = .,
    device = "jpeg",
    scale = 1,
    dpi = 300,
    width = 550, height = 280, units = "mm",
    limitsize = F
  )
