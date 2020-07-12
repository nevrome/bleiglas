library(magrittr)

load("inst/workflow_example/tesselation_calage_center_burial_type.RData")
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
jpeg(filename = "paper/05_3D_plot.jpeg", width = 22, height = 14, units = "cm", res = 300)

s <- scatterplot3d::scatterplot3d(
  threed$x, threed$y, threed$z, color = "red",
  cex.symbols = 0.7, angle = 70, pch = 18,
  xlab = "x [km]", ylab = "y [km]", zlab = "time [years calBC]",
  col.axis = "grey", mar = c(3,3,0,2),
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
