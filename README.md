
<!-- README.md is generated from README.Rmd. Please edit that file -->

# bleiglas

bleiglas is an R package that provides some helper functions for 3D
tessellation with [voro++](http://math.lbl.gov/voro++/) and subsequent
horizontal cutting of the resulting polygons for plotting. The general
workflow is described below.

### Get some data

Let’s get some data in three dimension with an arbitrary sample
variable. I decided to use @dirkseidenstickers *Archives des datations
radiocarbone d’Afrique centrale* dataset for this purpose. It includes
radiocarbon datings from Central Africa that combine spatial (x & y) and
temporal (z) information.

<details>

<summary>Click here for details of data preparation</summary>

<p>

I selected dates from Cameroon between 1000 and 3000 uncalibrated BP,
projected them on a simple cylindrical projection (epsg 4088). Cameroon
is so close to the equator, that this projection should even represent
distances, angles and areas quite correctly. I rescaled the temporal
data with a factor of 1000 to better show the effect of 3D tessellation.
You can imagine the samples to be observations in a 3D geo-time-space
where one year equals one kilometre. Samples with equal position in all
three dimensions have to be avoided.

``` r
c14_cmr <- c14bazAAR::get_c14data("adrac") %>% 
  dplyr::filter(!is.na(lat) & !is.na(lon), c14age > 1000, c14age < 3000, country == "CMR") 
```

    ## 
      |                                                        
      |                                                  |   0%
      |                                                        
      |++++++++++++++++++++++++++++++++++++++++++++++++++|  99%
      |                                                        
      |++++++++++++++++++++++++++++++++++++++++++++++++++| 100%

``` r
c14_cmr_unique <- c14_cmr %>%
  dplyr::mutate(
    rounded_coords_lat = round(lat, 3),
    rounded_coords_lon = round(lon, 3)
  ) %>%
  dplyr::group_by(rounded_coords_lat, rounded_coords_lon, c14age) %>%
  dplyr::filter(dplyr::row_number() == 1) %>%
  dplyr::ungroup()

coords <- data.frame(c14_cmr_unique$lon, c14_cmr_unique$lat) %>% 
  sf::st_as_sf(coords = c(1, 2), crs = 4326) %>% 
  sf::st_transform(crs = 4088) %>% 
  sf::st_coordinates()

c14 <- c14_cmr_unique %>% 
  dplyr::transmute(
    id = 1:nrow(.),
    x = coords[,1], 
    y = coords[,2], 
    z = c14age * 1000, # rescaling of temporal data
    material = material
)
```

</p>

</details>

<details>

<summary>Data: <b>c14</b></summary>

<p>

``` r
c14 
```

    ## # A tibble: 380 x 5
    ##       id        x       y       z material
    ##    <int>    <dbl>   <dbl>   <dbl> <chr>   
    ##  1     1 1284303. 450331. 1920000 <NA>    
    ##  2     2 1284303. 450331. 2596000 <NA>    
    ##  3     3 1284303. 450331. 2360000 <NA>    
    ##  4     4 1284303. 450331. 2380000 <NA>    
    ##  5     5 1278776. 434150. 2810000 <NA>    
    ##  6     6 1278776. 434150. 2710000 <NA>    
    ##  7     7 1278776. 434150. 1860000 <NA>    
    ##  8     8 1278776. 434150. 1960000 <NA>    
    ##  9     9 1278776. 434150. 2820000 <NA>    
    ## 10    10 1278776. 434150. 2110000 <NA>    
    ## # … with 370 more rows

</p>

</details>

### 3D tessellation

[Tessellation](https://en.wikipedia.org/wiki/Tessellation) means filling
space with polygons so that neither gaps nor overlaps occur. This is an
exciting application for art (e.g. textile art or architecture) and an
interesting challenge for mathematics. As a computational archaeologist
I know one particular tessellation algorithm that has quiet some
relevance for geostatistical operations like e.g. spatial interpolation:
Voronoi tilings as produced with [Delaunay
triangulation](https://en.wikipedia.org/wiki/Delaunay_triangulation).
These are tessellations where each polygon covers the space closest to
one of a set of sample points.

<table style="width:100%">

<tr>

<th>

<figure>

<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/6/66/Ceramic_Tile_Tessellations_in_Marrakech.jpg/320px-Ceramic_Tile_Tessellations_in_Marrakech.jpg" height="150" />

<figcaption>

Islamic mosaic with tile tessellations in Marrakech, Morocco.
<a href="https://en.wikipedia.org/wiki/File:Ceramic_Tile_Tessellations_in_Marrakech.jpg">wiki</a>

</figcaption>

</figure>

</th>

<th>

<figure>

<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/5/56/Delaunay_Voronoi.svg/441px-Delaunay_Voronoi.svg.png" height="150" />

<figcaption>

Delaunay triangulation and its Voronoi diagram.
<a href="https://commons.wikimedia.org/wiki/File:Delaunay_Voronoi.svg">wiki</a>

</figcaption>

</figure>

</th>

<th>

<figure>

<img src="http://math.lbl.gov/voro++/examples/custom_output/custom_output_l.png" height="150" />

<figcaption>

Output example of voro++ rendered with POV-Ray.
<a href="http://math.lbl.gov/voro++">math.lbl.gov</a>

</figcaption>

</figure>

</th>

<tr>

</table>

Voronoi tessellation can be calculated not just for 2D surfaces, but
also for higher dimensions. The [voro++](http://math.lbl.gov/voro++/)
software library does exactly this for 3D space.
`bleiglas::tessellate()` is a minimal wrapper function that calls the
voro++ command line interface for datasets like the one introduced
above. Therefore you have to install voro++ to use it.

``` r
raw_voro_output <- bleiglas::tessellate(
  c14[, c("id", "x", "y", "z")],
  x_min = min(c14$x) - 150000, x_max = max(c14$x) + 150000, 
  y_min = min(c14$y) - 150000, y_max = max(c14$y) + 150000
)
```

I increased the size of the tessellation box by 150 kilometres to each
(spatial) direction. voro++ prints some config info on the command line:

    Container geometry        : [937143:1.90688e+06] [63124.2:1.50658e+06] [1.01e+06:2.99e+06]
    Computational grid size   : 3 by 5 by 6 (estimated from file)
    Filename                  : /tmp/Rtmpf2W27D/file1932362bb49
    Output string             : %i§%P§%t
    Total imported particles  : 379 (4.2 per grid block)
    Total V. cells computed   : 379
    Total container volume    : 2.77155e+18
    Total V. cell volume      : 2.77156e+18

The output of voro++ is highly customizable, but structurally complex. I
focussed on the edges of the resulting 3D polygons and wrote a parser
function `bleiglas::read_polygon_edges()` that can transform it to a
tidy data.frame with the coordinates (x, y, z) of the start (a) and end
point (b) of each polygon edge.

``` r
polygon_edges <- bleiglas::read_polygon_edges(raw_voro_output)
```

<details>

<summary>Data</summary>

<p>

    ## # A tibble: 24,136 x 7
    ##        x.a    y.a     z.a     x.b    y.b     z.b    id
    ##      <dbl>  <dbl>   <dbl>   <dbl>  <dbl>   <dbl> <dbl>
    ##  1 1352610 233681 1240760 1381950 158990 1274740    38
    ##  2 1324180 130338 1292500 1381950 158990 1274740    38
    ##  3 1309730 225141 1313810 1381950 158990 1274740    38
    ##  4 1201420 392245 1299830 1289680 241638 1324360    38
    ##  5 1276830 227624 1327040 1289680 241638 1324360    38
    ##  6 1309730 225141 1313810 1289680 241638 1324360    38
    ##  7 1190420 336013 1202560  937143 326505 1224480    38
    ##  8  937143 374007 1308060  937143 326505 1224480    38
    ##  9  937143 185322 1292500  937143 326505 1224480    38
    ## 10  937143 326505 1224480 1190420 336013 1202560    38
    ## # … with 24,126 more rows

</p>

</details>

<details>

<summary>We can plot these polygon edges (black) together with the input
sample points (red) in 3D. Before we do that, we can change the scaling
of the temporal information again to increase the readability of the
plot.</summary>

<p>

``` r
polygon_edges %<>% dplyr::mutate(
  z.a = z.a / 1000,
  z.b = z.b / 1000
)

c14 %<>% dplyr::mutate(
  z = z / 1000
)
```

``` r
rgl::axes3d()
rgl::points3d(c14$x, c14$y, c14$z, color = "red")
rgl::aspect3d(1, 1, 1)
rgl::segments3d(
  x = as.vector(t(polygon_edges[,c(1,4)])),
  y = as.vector(t(polygon_edges[,c(2,5)])),
  z = as.vector(t(polygon_edges[,c(3,6)]))
)
rgl::view3d(userMatrix = view_matrix, zoom = 0.9)
```

</p>

</details>

<img src="README_files/figure-gfm/unnamed-chunk-8-1.png" style="display: block; margin: auto;" />

### Cutting the polygons

The static 3D plot is of rather dubious value for understanding the
tessellation. I therefore introduce the function
`bleiglas::cut_polygons()` that can cut the 3D polygons at different
levels of the z-axis. The function assumes x and y represent
geographical coordinates. The cuts therefore produce sets of spatial 2D
polygons at different values of z – in our example different points in
time. The parameter `cuts` takes a numeric vector of cutting points,
`crs` defines the spatial coordinate reference system of x and y to
project the resulting 2D polygons correctly.

``` r
cut_surfaces <- bleiglas::cut_polygons(
  polygon_edges, 
  cuts = c(2500, 2000, 1500), 
  crs = 4088
)
```

<details>

<summary>Data</summary>

<p>

    ## Simple feature collection with 74 features and 2 fields
    ## geometry type:  POLYGON
    ## dimension:      XY
    ## bbox:           xmin: 937143 ymin: 63124.2 xmax: 1906880 ymax: 1506580
    ## epsg (SRID):    4088
    ## proj4string:    +proj=eqc +lat_ts=0 +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +R=6371007 +units=m +no_defs
    ## First 10 features:
    ##     time  id                              x
    ## 16  2500  16 POLYGON ((1193932 315611.5,...
    ## 44  2500  44 POLYGON ((1906880 811490.3,...
    ## 51  2500  51 POLYGON ((1146789 374017.9,...
    ## 53  2500  53 POLYGON ((1195186 319422.3,...
    ## 82  2500  82 POLYGON ((1416023 455769.2,...
    ## 102 2500 102 POLYGON ((1082637 969464, 9...
    ## 104 2500 104 POLYGON ((1578607 63124.2, ...
    ## 134 2500 134 POLYGON ((1386791 333246.8,...
    ## 143 2500 143 POLYGON ((937143 63124.2, 9...
    ## 186 2500 186 POLYGON ((1116403 63124.2, ...

</p>

</details>

<details>

<summary>With this data we can plot a matrix of maps that show the cut
surfaces.</summary>

<p>

``` r
cut_surfaces %>%
  ggplot() +
  geom_sf(
    aes(fill = time), 
    color = "white",
    lwd = 0.2
  ) +
  geom_sf_text(aes(label = id)) +
  facet_wrap(~time) +
  theme(
    axis.text = element_blank(),
    axis.ticks = element_blank()
  )
```

</p>

</details>

<img src="README_files/figure-gfm/unnamed-chunk-12-1.png" style="display: block; margin: auto;" />

<details>

<summary>As all input dates come from Cameroon it might be a sensible
decision to cut the polygon surfaces to the outline of this
administrative, spatial unit.</summary>

<p>

``` r
cameroon_border <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf") %>% 
  dplyr::filter(name_en == "Cameroon") %>% 
  sf::st_transform(4088)

cut_surfaces_cropped <- cut_surfaces %>% sf::st_intersection(cameroon_border)
```

``` r
cut_surfaces_cropped %>%
  ggplot() +
  geom_sf(
    aes(fill = time), 
    color = "white",
    lwd = 0.2
  ) +
  facet_wrap(~time) +
  theme(
    axis.text = element_blank(),
    axis.ticks = element_blank()
  )
```

<p>

</details>

<img src="README_files/figure-gfm/unnamed-chunk-15-1.png" style="display: block; margin: auto;" />

<details>

<summary>Of course we can visualise any point-wise information we
initially had as a feature of the tessellation polygons.</summary>

<p>

``` r
cut_surfaces_material <- cut_surfaces_cropped %>%
  dplyr::left_join(
    c14, by = "id"
  )
```

``` r
cut_surfaces_material %>%
  ggplot() +
  geom_sf(
    aes(fill = material), 
    color = "white",
    lwd = 0.2
  ) +
  facet_wrap(~time) +
  theme(
    axis.text = element_blank(),
    axis.ticks = element_blank()
  )
```

</p>

</details>

<img src="README_files/figure-gfm/unnamed-chunk-18-1.png" style="display: block; margin: auto;" />
