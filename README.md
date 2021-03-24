
[![Project Status: Inactive – The project has reached a stable, usable
state but is no longer being actively developed; support/maintenance
will be provided as time
allows.](https://www.repostatus.org/badges/latest/inactive.svg)](https://www.repostatus.org/#inactive)
![GitHub R package
version](https://img.shields.io/github/r-package/v/nevrome/bleiglas)
[![Travis-CI Build
Status](https://travis-ci.com/nevrome/bleiglas.svg?branch=master)](https://travis-ci.com/nevrome/bleiglas)
[![Coverage
Status](https://img.shields.io/codecov/c/github/nevrome/bleiglas/master.svg)](https://codecov.io/github/nevrome/bleiglas?branch=master)
[![license](https://img.shields.io/github/license/nevrome/bleiglas)](https://www.r-project.org/Licenses/MIT)

<!-- README.md is generated from README.Rmd. Please edit that file -->

# bleiglas

bleiglas is an R package that provides functions for 3D tessellation
with [Voro++](http://math.lbl.gov/voro++/) and subsequent horizontal
cutting of the resulting polygons for 2D plotting. It was developed for
archaeological spatiotemporal data, but may as well be used for other
three dimensional contexts.

## Documentation

1.  This README (see Quickstart guide below) describes a basic workflow
    with code and explains some of my thought process when writing this
    package
2.  A [JOSS
    paper](https://github.com/nevrome/bleiglas/blob/master/paper/paper.md)
    (in Review) which gives some background, introduces the core
    functions from a more technical point of view and presents an
    example application
3.  A (rather technical)
    [vignette](https://github.com/nevrome/bleiglas/blob/master/vignettes/complete_example.Rmd)
    which contains all the code necessary to reproduce the example
    application in said JOSS paper

If you have questions beyond this documentation feel free to open an
[issue](https://github.com/nevrome/bleiglas/issues) here on Github.
Please also see our [contributing guide](CONTRIBUTING.md).

## Installation

You can install bleiglas from github

``` r
if(!require('remotes')) install.packages('remotes')
remotes::install_github("nevrome/bleiglas")
```

For the main function `tessellate` you also have to [install the Voro++
software](http://math.lbl.gov/voro++/download/). The package is already
available in all major Linux software repositories (on Debian/Ubuntu you
can simply run `sudo apt-get install voro++`.). MacOS users should be
able to install it via homebrew (`brew install voro++`).

## Quickstart

For this quickstart, we assume you have packages `tidyverse`, `sf`,
`rgeos` (which in turn requires the Unix package `geos`) and `c14bazAAR`
installed.

#### Getting some data

I decided to use Dirk Seidenstickers [*Archives des datations
radiocarbone d’Afrique
centrale*](https://github.com/dirkseidensticker/aDRAC) dataset for this
purpose. It includes radiocarbon datings from Central Africa that
combine spatial (x & y) and temporal (z) position with some meta
information.

<details>
<summary>
Click here for the data preparation steps
</summary>
<p>

I selected dates from Cameroon between 1000 and 3000 uncalibrated BP and
projected them into a worldwide cylindrical reference system (epsg
[4088](https://epsg.io/4088)). As Cameroon is close to the equator this
projection should represent distances, angles and areas sufficiently
correct for this example exercise. As a minor pre-processing step, I
here also remove samples with equal position in all three dimensions for
the tessellation.

``` r
# download raw data with the data access package c14bazAAR
# c14bazAAR can be installed with
# install.packages("c14bazAAR", repos = c(ropensci = "https://ropensci.r-universe.dev"))
c14_cmr <- c14bazAAR::get_c14data("adrac") %>% 
  # filter data
  dplyr::filter(!is.na(lat) & !is.na(lon), c14age > 1000, c14age < 3000, country == "CMR") 
```

    ##   |                                                          |                                                  |   0%  |                                                          |++++++++++++++++++++++++++++++++++++++++++++++++++|  99%  |                                                          |++++++++++++++++++++++++++++++++++++++++++++++++++| 100%

``` r
# remove doubles
c14_cmr_unique <- c14_cmr %>%
  dplyr::mutate(
    rounded_coords_lat = round(lat, 3),
    rounded_coords_lon = round(lon, 3)
  ) %>%
  dplyr::group_by(rounded_coords_lat, rounded_coords_lon, c14age) %>%
  dplyr::filter(dplyr::row_number() == 1) %>%
  dplyr::ungroup()

# transform coordinates
coords <- data.frame(c14_cmr_unique$lon, c14_cmr_unique$lat) %>% 
  sf::st_as_sf(coords = c(1, 2), crs = 4326) %>% 
  sf::st_transform(crs = 4088) %>% 
  sf::st_coordinates()

# create active dataset
c14 <- c14_cmr_unique %>% 
  dplyr::transmute(
    id = 1:nrow(.),
    x = coords[,1], 
    y = coords[,2], 
    z = c14age,
    period = period
)
```

</p>
</details>
<details>
<summary>
Data: <b>c14</b>
</summary>
<p>

``` r
c14 
```

    ## # A tibble: 393 x 5
    ##       id        x       y     z period
    ##    <int>    <dbl>   <dbl> <int> <chr> 
    ##  1     1 1284303. 450340.  1920 EIA   
    ##  2     2 1101276. 321798.  2340 EIA   
    ##  3     3 1101276. 321798.  2520 LSA   
    ##  4     4 1093159. 264311.  2000 <NA>  
    ##  5     5 1132077. 340034.  1670 <NA>  
    ##  6     6 1101276. 321798.  2200 <NA>  
    ##  7     7 1101276. 321798.  2030 <NA>  
    ##  8     8 1101276. 321798.  1760 EIA   
    ##  9     9 1093159. 264311.  1710 <NA>  
    ## 10    10 1093159. 264311.  1940 <NA>  
    ## # … with 383 more rows

</p>
</details>

#### 3D tessellation

[Tessellation](https://en.wikipedia.org/wiki/Tessellation) means filling
space with polygons so that neither gaps nor overlaps occur. This is an
exciting application for art (e.g. textile art or architecture) and an
interesting challenge for mathematics. As a computational archaeologist
I was already aware of one particular tessellation algorithm that has
quite some relevance for geostatistical analysis like spatial
interpolation: Voronoi tilings that are created with [Delaunay
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
Output example of Voro++ rendered with POV-Ray.
<a href="http://math.lbl.gov/voro++">math.lbl.gov</a>
</figcaption>
</figure>
</th>
<tr>
</table>

It turns out that Voronoi tessellation can be calculated not just for 2D
surfaces, but also for higher dimensions. The
[Voro++](http://math.lbl.gov/voro++/) software library does exactly this
for 3 dimensions. This makes it useful for spatio-temporal applications.

`bleiglas::tessellate()` is a minimal wrapper function that calls the
Voro++ command line interface (therefore you have to install Voro++ to
use it) for datasets like the one introduced above. We can apply it like
this:

``` r
raw_voro_output <- bleiglas::tessellate(
  c14[, c("id", "x", "y", "z")],
  x_min = min(c14$x) - 150000, x_max = max(c14$x) + 150000, 
  y_min = min(c14$y) - 150000, y_max = max(c14$y) + 150000,
  unit_scaling = c(0.001, 0.001, 1)
)
```

A critical step when using tessellation for spatio-temporal data is a
suitable conversion scale between time- and spatial units. Since 3D
tessellation crucially depends on the concept of a 3D-distance, we need
to make a decision how to combine length- and time-units. Here, for the
purpose of this example, we have 1 kilometre correspond to 1 year. Since
after the coordinate conversion our spatial units are given in meters,
we divide all spatial distances by a factor 1000 to achieve this
correspondence: `unit_scaling = c(0.001, 0.001, 1)`.

I decided to increase the size of the tessellation box by 150 kilometres
to each (spatial) direction to cover the area of Cameroon. Mind that the
scaling factors in `unit_scaling` are also applied to the box size
parameters `x_min`, `x_max`, ….

The output of Voro++ is highly customizable, and structurally complex.
With the `-v` flag, the voro++ CLI interface prints some config info,
which is also the output of `bleiglas::tesselate`:

    Container geometry        : [937.154:1936.57] [63.1609:1506.58] [1010:2990]
    Computational grid size   : 3 by 5 by 6 (estimated from file)
    Filename                  : /tmp/RtmpVZjBW3/file3aeb5f400f38
    Output string             : %i*%P*%t
    Total imported particles  : 392 (4.4 per grid block)
    Total V. cells computed   : 392
    Total container volume    : 2.8563e+09
    Total V. cell volume      : 2.8563e+09

It then produces an output file (`*.vol`) that contains all sorts of
geometry information for the calculated 3D polygons. `tesselate` returns
the content of this file as a character vector with the additionally
attached attribute `unit_scaling`
(`attributes(raw_voro_output)$unit_scaling`), which is just the scaling
vector we put in above.

I focussed on the edges of the polygons and wrote a parser function
`bleiglas::read_polygon_edges()` that can transform the complex Voro++
output for this specific output case to a tidy data.frame with six
columns: the coordinates (x, y, z) of the start (a) and end point (b) of
each polygon edge.

``` r
polygon_edges <- bleiglas::read_polygon_edges(raw_voro_output)
```

`read_polygon_edges` also automatically reverses the rescaling
introduced in `tesselate` with the `unit_scaling` attribute.

<details>
<summary>
Data: <b>polygon\_edges</b>
</summary>
<p>

    ##            x.a     y.a     z.a     x.b    y.b     z.b polygon_id
    ##     1:  937154  374130 1307.99 1201480 392161 1299.80         25
    ##     2: 1289460  241706 1324.42 1201480 392161 1299.80         25
    ##     3: 1212280  387619 1290.18 1201480 392161 1299.80         25
    ##     4: 1190480  335990 1202.59 1233970 377206 1268.57         25
    ##     5: 1352310  233958 1240.81 1233970 377206 1268.57         25
    ##    ---                                                          
    ## 24916: 1341410 1041000 2655.00 1645270 892489 2655.00        290
    ## 24917: 1622180  900165 2682.50 1645270 892489 2655.00        290
    ## 24918: 1361490 1027580 2682.50 1622180 900165 2682.50        290
    ## 24919: 1596200  911750 2731.50 1622180 900165 2682.50        290
    ## 24920: 1645270  892489 2655.00 1622180 900165 2682.50        290

</p>
</details>
<details>
<summary>
We can plot these polygon edges (black) together with the input sample
points (red) in 3D.
</summary>
<p>

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

#### Cutting the polygons

This 3D plot, even if rotatable using mouse input, is of rather limited
value since it’s very hard to read. I therefore wrote
`bleiglas::cut_polygons()` that can cut the 3D polygons at different
levels of the z-axis. As the function assumes that x and y represent
geographic coordinates, the cuts produce sets of spatial 2D polygons for
different values of z – in our example different points in time. The
parameter `cuts` takes a numeric vector of cutting points on the z axis.
`bleiglas::cut_polygons()` yields a rather raw format for specifying
polygons. Another function, `bleiglas::cut_polygons_to_sf()`, transforms
it to `sf`. Here `crs` defines the spatial coordinate reference system
of x and y to project the resulting 2D polygons correctly.

``` r
cut_surfaces <- bleiglas::cut_polygons(
  polygon_edges, 
  cuts = c(2500, 2000, 1500)
) %>%
  bleiglas::cut_polygons_to_sf(crs = 4088)
```

<details>
<summary>
Data: <b>cut\_surfaces</b>
</summary>
<p>

    ## Simple feature collection with 76 features and 2 fields
    ## geometry type:  POLYGON
    ## dimension:      XY
    ## bbox:           xmin: 937154 ymin: 63160.9 xmax: 1936570 ymax: 1506580
    ## projected CRS:  World Equidistant Cylindrical (Sphere)
    ## First 10 features:
    ##                                 x    z  id
    ## 1  POLYGON ((1195386 319810.5,... 2500   3
    ## 2  POLYGON ((1936570 809055.4,... 2500  31
    ## 3  POLYGON ((1146675 374628.2,... 2500  38
    ## 4  POLYGON ((1215947 365177.1,... 2500  40
    ## 5  POLYGON ((1416056 455852, 1... 2500  69
    ## 6  POLYGON ((1082719 969489.5,... 2500 103
    ## 7  POLYGON ((1936570 315020.3,... 2500 105
    ## 8  POLYGON ((1386575 333838.1,... 2500 135
    ## 9  POLYGON ((1116416 63160.9, ... 2500 144
    ## 10 POLYGON ((1377347 63160.9, ... 2500 185

</p>
</details>
<details>
<summary>
With this data we can plot a matrix of maps that show the cut surfaces.
</summary>
<p>

``` r
cut_surfaces %>%
  ggplot() +
  geom_sf(
    aes(fill = z), 
    color = "white",
    lwd = 0.2
  ) +
  geom_sf_text(aes(label = id)) +
  facet_wrap(~z) +
  theme(
    axis.text = element_blank(),
    axis.ticks = element_blank()
  )
```

</p>
</details>

<img src="README_files/figure-gfm/unnamed-chunk-12-1.png" style="display: block; margin: auto;" />

<details>
<summary>
As all input dates come from Cameroon it makes sense to cut the polygon
surfaces to the outline of this administrative unit.
</summary>
<p>

``` r
cameroon_border <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf") %>% 
  dplyr::filter(name == "Cameroon") %>% 
  sf::st_transform(4088)

cut_surfaces_cropped <- cut_surfaces %>% sf::st_intersection(cameroon_border)
```

``` r
cut_surfaces_cropped %>%
  ggplot() +
  geom_sf(
    aes(fill = z), 
    color = "white",
    lwd = 0.2
  ) +
  facet_wrap(~z) +
  theme(
    axis.text = element_blank(),
    axis.ticks = element_blank()
  )
```

<p>
</details>

<img src="README_files/figure-gfm/unnamed-chunk-15-1.png" style="display: block; margin: auto;" />

<details>
<summary>
Finally, we can also visualise any point-wise information in our input
data as a feature of the tessellation polygons.
</summary>
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
    aes(fill = period), 
    color = "white",
    lwd = 0.2
  ) +
  facet_wrap(~z.x) +
  theme(
    axis.text = element_blank(),
    axis.ticks = element_blank()
  )
```

</p>
</details>

<img src="README_files/figure-gfm/unnamed-chunk-18-1.png" style="display: block; margin: auto;" />

This quickstart was a simple primer on how to use this package. If you
think the final use case wasn’t too impressive, take a look at this
analysis of Bronze Age burial types through time, as performed in our
[JOSS
paper](https://github.com/nevrome/bleiglas/blob/master/paper/paper.md)
and the
[vignette](https://github.com/nevrome/bleiglas/blob/master/vignettes/complete_example.Rmd).

<!-- Add JOSS paper figure here? Just a suggestion as a further teaser. It's just beautiful -->

## Citation

    ## 
    ## To cite package 'bleiglas' in publications use:
    ## 
    ##   Clemens Schmid (2020). bleiglas: Spatiotemporal Data Interpolation
    ##   and Visualisation based on 3D Tessellation with Voro++. R package
    ##   version 0.1.1. https://github.com/nevrome/bleiglas
    ## 
    ## A BibTeX entry for LaTeX users is
    ## 
    ##   @Manual{,
    ##     title = {bleiglas: Spatiotemporal Data Interpolation and Visualisation based on 3D Tessellation with Voro++},
    ##     author = {Clemens Schmid},
    ##     year = {2020},
    ##     note = {R package version 0.1.1},
    ##     url = {https://github.com/nevrome/bleiglas},
    ##   }
