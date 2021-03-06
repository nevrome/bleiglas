library(magrittr)
library(ggplot2)

load("inst/workflow_example/dates_prepared.RData")
load("inst/workflow_example/research_area.RData")
load("inst/workflow_example/extended_area.RData")
load("inst/workflow_example/epsg102013.RData")

ex <- raster::extent(research_area)
xlimit <- c(ex[1], ex[2])
ylimit <- c(ex[3], ex[4])

p <- ggplot() +
  geom_sf(
    data = extended_area,
    fill = "white", colour = "black", size = 0.4
  ) +
  geom_sf(
    data = research_area,
    fill = NA, colour = "black", size = 0.5
  ) +
  geom_point(
    data = dates_prepared,
    mapping = aes(
      x = x,
      y = y,
      color = burial_type,
      shape = burial_construction,
      size = burial_construction
    )
  ) +
  theme_bw() +
  coord_sf(
    xlim = xlimit, ylim = ylimit,
    crs = sf::st_crs(epsg102013)
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
    legend.position = "right",
    legend.title = element_text(size = 19, face = "bold"),
    axis.title = element_blank(),
    axis.text = element_text(size = 20),
    legend.text = element_text(size = 19),
    panel.background = element_rect(fill = "#BFD5E3")
  ) +
  guides(
    color = guide_legend(
      title = "Burial type", override.aes = list(size = 10), 
      nrow = 2, byrow = TRUE, order = 1
    ),
    shape = guide_legend(
      title = "Burial construction", override.aes = list(size = 10), 
      nrow = 2, byrow = TRUE, order = 2
    ),
    size = FALSE,
    alpha = guide_legend(
      title = "Calibration density", override.aes = list(size = 10, shape = 15),
      nrow = 2, byrow = TRUE, order = 3
    )
  )

### save plot ####

p %>%
  ggsave(
    "inst/workflow_example/03_map_plot.jpeg",
    plot = .,
    device = "jpeg",
    scale = 1,
    dpi = 72,
    width = 400, height = 250, units = "mm",
    limitsize = F
  )

p %>%
  ggsave(
    "paper/03_map_plot.jpeg",
    plot = .,
    device = "jpeg",
    scale = 1,
    dpi = 300,
    width = 400, height = 250, units = "mm",
    limitsize = F
  )
