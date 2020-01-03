
<!-- README.md is generated from README.Rmd. Please edit that file -->

# bleiglas

bleiglas is an R package that provides some helper functions for 3D
tessellation and subsequent cutting of the resulting polygons along one
dimension for plotting.

## 3D tessellation

Let’s get some data in three dimension with an arbitrary sample
variable. I decided to use @dirkseidenstickers *Archives des datations
radiocarbone d’Afrique centrale* dataset for this purpose. It includes
radiocarbon datings

<details>

<summary>Click here for details of data
preparation</summary>

<p>

``` r
c14_cmr <- c14bazAAR::get_c14data("adrac") %>% dplyr::filter(!is.na(lat) & !is.na(lon), c14age > 1000, c14age < 3000, country == "CMR")
```

    ##   |                                                          |                                                  |   0%  |                                                          |++++++++++++++++++++++++++++++++++++++++++++++++++|  99%  |                                                          |++++++++++++++++++++++++++++++++++++++++++++++++++| 100%

``` r
coords <- data.frame(c14_cmr$lat, c14_cmr$lon) %>% sf::st_as_sf(coords = c(1, 2), crs = 4326) %>% sf::st_transform(crs = 4088) %>% sf::st_coordinates()
c14 <- c14_cmr %>% dplyr::transmute(x = coords[,1], y = coords[,2], z = c14age * 1000) # necessary rescaling of temporal data
```

</p>

</details>

``` r
c14 
```

    ##  Radiocarbon date list
    ##  dates       405 
    ## 
    ## # A tibble: 405 x 3
    ##          x        y       z
    ##      <dbl>    <dbl>   <dbl>
    ##  1 450331. 1284303. 1920000
    ##  2 450331. 1284303. 2596000
    ##  3 450331. 1284303. 2360000
    ##  4 450331. 1284303. 2380000
    ##  5 434150. 1278776. 2810000
    ##  6 434150. 1278776. 2710000
    ##  7 434150. 1278776. 1860000
    ##  8 434150. 1278776. 1960000
    ##  9 434150. 1278776. 2820000
    ## 10 434150. 1278776. 2110000
    ## # … with 395 more rows
