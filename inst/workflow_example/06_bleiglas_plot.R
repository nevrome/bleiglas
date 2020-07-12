library(magrittr)
library(ggplot2)

load("inst/workflow_example/tesselation_calage_center_burial_type.RData")
load("inst/workflow_example/research_area.RData")
load("inst/workflow_example/extended_area.RData")

ex <- raster::extent(research_area)
xlimit <- c(ex[1], ex[2])
ylimit <- c(ex[3], ex[4])

#### plot bleiglasfenster plot ####
p <- cut_surfaces_info %>%
  ggplot() +
  geom_sf(
    data = extended_area,
    fill = "white", colour = "black", size = 0.4
  ) +
  geom_sf(
    aes(fill = burial_type), 
    color = "white", lwd = 0.3
  ) +
  geom_sf(
    data = extended_area,
    fill = NA, colour = "black", size = 0.4
  ) +
  geom_sf(
    data = research_area,
    fill = NA, colour = "black", size = 0.5
  ) +
  scale_fill_manual(
    values = c(
      "cremation" = "#D55E00",
      "inhumation" = "#0072B2",
      "mound" = "#CC79A7",
      "flat" = "#009E73",
      "unknown" = "grey85"
    )
  ) +
  facet_wrap(~time, nrow = 2) +
  coord_sf(
    xlim = xlimit, ylim = ylimit,
    crs = sf::st_crs("+proj=aea +lat_1=43 +lat_2=62 +lat_0=30 +lon_0=10 +x_0=0 +y_0=0 +ellps=intl +units=m +no_defs")
  ) +
  guides(
    fill = guide_legend(title = "Burial type", override.aes = list(size = 10), nrow = 1, byrow = TRUE)
  ) +
  theme_bw() +
  theme(
    plot.title = element_text(size = 30, face = "bold"),
    legend.position = "bottom",
    legend.title = element_text(size = 20, face = "bold"),
    axis.title = element_blank(),
    axis.text = element_blank(),
    legend.text = element_text(size = 20),
    strip.text.x = element_text(size = 20),
    panel.background = element_rect(fill = "#BFD5E3")
  ) 

p %>% 
  ggsave(
    "paper/06_bleiglas_plot.jpeg",
    plot = .,
    device = "jpeg",
    scale = 1,
    dpi = 300,
    width = 550, height = 280, units = "mm",
    limitsize = F
  )
