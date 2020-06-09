library(magrittr)
library(ggplot2)

load("inst/workflow_example/dates_prepared.RData")
load("inst/workflow_example/research_area.RData")
load("inst/workflow_example/extended_area.RData")

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
    legend.position = "bottom",
    legend.title = element_text(size = 19, face = "bold"),
    axis.title = element_blank(),
    axis.text = element_text(size = 20),
    legend.text = element_text(size = 19),
    panel.background = element_rect(fill = "#BFD5E3")
  ) +
  guides(
    color = guide_legend(title = "Burial type", override.aes = list(size = 10), nrow = 2, byrow = TRUE, order = 1),
    shape = guide_legend(title = "Burial construction", override.aes = list(size = 10), nrow = 2, byrow = TRUE, order = 2),
    size = FALSE,
    alpha = guide_legend(title = "Calibration density", override.aes = list(size = 10, shape = 15), nrow = 2, byrow = TRUE, order = 3)
  )

hu %>%
  ggsave(
    "paper/01_map_plot.jpeg",
    plot = .,
    device = "jpeg",
    scale = 1,
    dpi = 300,
    width = 300, height = 280, units = "mm",
    limitsize = F
  )

#########################################################################

library(magrittr)

load("paper/workflow_example/tesselation_calage_center_burial_type.RData")
load("inst/workflow_example/research_area.RData")
raps <- sf::st_coordinates(sf::st_cast(research_area, "POINT"))[1:4,]/1000

#### 3d plot rgl #### 
# rgl::axes3d()
# rgl::points3d(vertices$x, vertices$y, vertices$z, color = "red")
# rgl::aspect3d(1, 1, 1)
# rgl::segments3d(
#   x = as.vector(t(polygon_edges[,c(1,4)])),
#   y = as.vector(t(polygon_edges[,c(2,5)])),
#   z = as.vector(t(polygon_edges[,c(3,6)]))
# )

# rgl::writeWebGL(filename = "plots/tesselation.html",  width = 700, height = 700)

threed <- vertices %>%
  dplyr::transmute(
    x = x/1000, 
    y = y/1000,
    z = z
  )

polygon_edges$x.a <- polygon_edges$x.a/1000
polygon_edges$y.a <- polygon_edges$y.a/1000
polygon_edges$x.b <- polygon_edges$x.b/1000
polygon_edges$y.b <- polygon_edges$y.b/1000

# plot
png(filename = "paper/03_3D_plot.png", width = 22, height = 18, units = "cm", res = 300)

s <- scatterplot3d::scatterplot3d(
  threed$x, threed$y, threed$z, color = "red",
  cex.symbols = 0.7, angle = 70, pch = 18,
  xlab = "x", ylab = "y", zlab = "time calBC",
  col.axis = "grey",
  xlim = c(-1700, 1200), ylim = c(1000, 3500), zlim = c(-2300, -700)
)

#### tesselation ####
csstart <- s$xyz.convert(polygon_edges[[1]], polygon_edges[[2]], polygon_edges[[3]])
csstop <- s$xyz.convert(polygon_edges[[4]], polygon_edges[[5]], polygon_edges[[6]])
for(i in 1:length(csstart$x)) {
  segments(csstart$x[i], csstart$y[i], csstop$x[i], csstop$y[i], lwd = 0.1, col = "black")
}

#### research area box ####
a1 <- s$xyz.convert(raps[1,1], raps[1,2], -2200)
a2 <- s$xyz.convert(raps[2,1], raps[2,2], -2200)
a3 <- s$xyz.convert(raps[3,1], raps[3,2], -2200)
a4 <- s$xyz.convert(raps[4,1], raps[4,2], -2200)

b1 <- s$xyz.convert(raps[1,1], raps[1,2], -800)
b2 <- s$xyz.convert(raps[2,1], raps[2,2], -800)
b3 <- s$xyz.convert(raps[3,1], raps[3,2], -800)
b4 <- s$xyz.convert(raps[4,1], raps[4,2], -800)

segments(a1$x, a1$y, a2$x, a2$y, lwd = 1, col = "black")
segments(a2$x, a2$y, a3$x, a3$y, lwd = 1, col = "black")
segments(a3$x, a3$y, a4$x, a4$y, lwd = 1, col = "black")
segments(a4$x, a4$y, a1$x, a1$y, lwd = 1, col = "black")

segments(b1$x, b1$y, b2$x, b2$y, lwd = 1, col = "black")
segments(b2$x, b2$y, b3$x, b3$y, lwd = 1, col = "black")
segments(b3$x, b3$y, b4$x, b4$y, lwd = 1, col = "black")
segments(b4$x, b4$y, b1$x, b1$y, lwd = 1, col = "black")

segments(a1$x, a1$y, b1$x, b1$y, lwd = 1, col = "black")
segments(a2$x, a2$y, b2$x, b2$y, lwd = 1, col = "black")
segments(a3$x, a3$y, b3$x, b3$y, lwd = 1, col = "black")
segments(a4$x, a4$y, b4$x, b4$y, lwd = 1, col = "black")

dev.off()

#########################################################################

library(magrittr)
library(ggplot2)

load("paper/workflow_example/tesselation_calage_center_burial_type.RData")
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
    panel.grid.major = element_line(colour = "grey", size = 0.3),
    strip.text.x = element_text(size = 20),
    panel.background = element_rect(fill = "#BFD5E3")
  ) 

p %>% 
  ggsave(
    "paper/04_bleiglas_plot.png",
    plot = .,
    device = "png",
    scale = 1,
    dpi = 300,
    width = 550, height = 280, units = "mm",
    limitsize = F
  )

