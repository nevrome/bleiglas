library(magrittr)

load("inst/workflow_example/tesselation_calage_center_burial_type.RData")
load("inst/workflow_example/research_area.RData")

#### prepare vertex data ####

threed <- vertices %>%
  dplyr::transmute(
    # scale to kilometres from meters
    x = x/1000, 
    y = y/1000,
    z = z
  )

polygon_edges$x.a <- polygon_edges$x.a/1000
polygon_edges$y.a <- polygon_edges$y.a/1000
polygon_edges$x.b <- polygon_edges$x.b/1000
polygon_edges$y.b <- polygon_edges$y.b/1000

#### 3D plot construction ####

plot_my_3d <- function() {
  # vertex points
  s <- scatterplot3d::scatterplot3d(
    threed$x, threed$y, threed$z, color = "red",
    cex.symbols = 0.7, angle = 70, pch = 18,
    xlab = "x [km]", ylab = "y [km]", zlab = "time [years calBC]",
    col.axis = "grey", mar = c(3,3,0,2),
    xlim = c(-1700, 1200), ylim = c(1000, 3500), zlim = c(-2300, -700)
  )
  
  # tessellation polygon edges
  csstart <- s$xyz.convert(
    polygon_edges[[1]], 
    polygon_edges[[2]], 
    polygon_edges[[3]]
  )
  csstop <- s$xyz.convert(
    polygon_edges[[4]], 
    polygon_edges[[5]], 
    polygon_edges[[6]]
  )
  for(i in seq_along(csstart$x)) {
    segments(
      csstart$x[i], csstart$y[i], csstop$x[i], csstop$y[i], 
      lwd = 0.1, col = "black"
    )
  }
  
  # research area box
  raps <- sf::st_coordinates(sf::st_cast(research_area, "POINT"))[1:4,]/1000
  
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
}

#### save plot ####

jpeg(
  filename = "inst/workflow_example/05_3D_plot.jpeg", 
  width = 22, height = 14, units = "cm", res = 72
)
plot_my_3d()
dev.off()

jpeg(
  filename = "paper/05_3D_plot.jpeg", 
  width = 22, height = 14, units = "cm", res = 300
)
plot_my_3d()
dev.off()
