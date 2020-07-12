---
title: 'bleiglas: An R package for 3D tessellation with voro++'
tags:
  - R
  - 3D data analysis
  - tessellation
  - Voronoi diagrams
  - Spatiotemporal analysis
  - Archaeology
authors:
  - name: Clemens Schmid
    orcid: 0000-0003-3448-5715
    affiliation: 1
  - name: Stephan Schiffels
    orcid: 0000-0002-1017-9150
    affiliation: 1
affiliations:
  - name: Department of Archaeogenetics, Max Planck Institute for the Science of Human History, Kahlaische Strasse 10, 07745 Jena, Germany
    index: 1
date: 07 June 2020
bibliography: paper.bib
---

# Background

The open source software library [voro++](http://math.lbl.gov/voro++) [@Rycroft2009-rp] allows fast calculation of Voronoi diagrams in three dimensions. Voronoi diagrams are a special form of tessellation (i.e. filling space with geometric shapes without gaps or overlaps), where each polygon is defined as the region consisting of all points closest to one particular seed point. Imagine a volume in three dimensional space and an arbitrary distribution of unique points within this volume. voro++ creates a polygon around each point so that everything within this polygon is closest to the corresponding point and farther away from every other point.

Voronoi tessellation has useful applications in all kinds of scientific contexts spanning astronomy (e.g. @Paranjape2020-sg) material science (e.g. @Tsuru2020-ep) or geography (e.g. @Liu2019-fw). From the point of view of computational and landscape archaeology, delaunay triangulation and voronoi diagrams were as well applied as tools for data analysis [@Nakoinz2016-bq], but so far to our knowledge limited to an entirely spatial 2D perspective. 3D tessellation could be employed here to add a third dimension, most intriguingly a temporal one. This could allow for new methods of spatiotemporal data analysis and visualization as demonstrated in the example in the package vignette and briefly summarised below.

The ``bleiglas`` R package serves as an R interface to the voro++ command line tool. It adds a number of utility functions for particular data manipulation applications, including but not limited to automatic cutting of the 3D voro++ output for subsequent mapping and grid sampling for position and value uncertainty mitigation. The relevant workflows are explained below. Although we wrote this package for our own needs in archaeology and archaeogenetics, the code is by no means restricted to data from these fields, just as voronoi tessellation is a generic, subject-agnostic method with a huge range of use-cases.

# Core functionality

``bleiglas`` provides the `bleiglas::tessellate()` function which is a a command line utility wrapper for voro++. It requires voro++ to be installed locally. `tessellate()` takes input points in the form of a `data.frame` with an integer ID and three numeric coordinate columns. Additional voro++ [options](http://math.lbl.gov/voro++/doc/cmd.html) can be set with a character argument `options` and only the [output format definition](http://math.lbl.gov/voro++/doc/custom.html) (`-c`) is lifted to an extra character argument `output_definition`. `tessellate()` returns a character vector containing the raw output of voro++ with one vector element corresponding to one row. Depending on the structure of this raw output, different parsing functions are required to transform it to an useful R object. At the moment, ``bleiglas`` only provides one such function: `bleiglas::read_polygon_edges()`. It is configured to read data produced with the voro++ output format string `%i*%P*%t`, which returns polygon edge coordinates necessary for the default ``bleiglas`` workflow illustrated in the example below. Future versions of the package may include other parsing functions for different pipelines.

The output of `read_polygon_edges()` is (for performance reasons) a `data.table` [@Dowle2019] object that can be used with `bleiglas::cut_polygons()`. This function now shoulders the core task of cutting the polgyon-filled voro++ output box into 2D slices. 3D data is notoriously difficult to plot and read. Extracting and visualizing slices is therefore indispensable. The necessary algorithm for each 3D polygon can be summarised as finding the cutting point of each polygon edge line with the requested cutting surface and then defining the convex hull of the cutting points as a result 2D polygon. We implemented the line-segment-plane-intersection operation via Rcpp [@Eddelbuettel2017] in C++ for better performance and used `grDevices::chull` for the convex hull search. The output of `cut_polygons()` is a list (for each cut surface) of lists (for each polygon) of `data.table`s (3D coordinates for each 2D cutting point). Optionally, and in case of horizontal (z-axis) cuts with spatial coordinates on the x- and y-axis, this output can be transformed to an `sf` [@Pebesma2018] object via `bleiglas::cut_polygons_to_sf()`. This significantly simplifies subsequent map plotting.

The final core function of ``bleiglas`` is `bleiglas::predict_grid()` which paves the way for more complex applications and data subject to a higher degree of positional uncertainty. It employs the tessellation output to predict values at arbitrary positions by determining in which 3D polygons they are located. The core algorithm `bleiglas::attribute_grid_points_to_polygons()` uses `cut_polygons()` to cut the tesselation volume at the z-axis level of each the prediction point and then checks in which 2D polygon the point is located to attribute it its values. This is done with custom C++ code initially developed for our recexcavAAR package [@Schmid2017]. `bleiglas::predict_grid()` can be used to automatically rerun tessellation multiple times for data with uncertain position in one or multiple of the three dimensions. The resulting wiggling of input points and therefore output polygons can be recorded with the static prediction grid. Finally the different per-prediction-point observations in the grid can be summarised to calculate mean outcomes and deviation. One concrete archaeological application of this feature is temporal resampling from post-calibration radiocarbon age probability distributions.

A prerequisite for performing tesselation in three dimensions is the normalization or mapping of length units across three dimensions. If all three dimensions have the same units (as is the case for 3D spatial data), this is not an issue, and tesselation works as expected. However, if dimensions have different units, the outcome and meaning of the tesselation depends crucially on how these units are mapped to each other. This is the case for spatiotemporal data, in which one axis denotes time and the other two axes denote a 2D spatial position. In such cases it is critical to use external information to inform on an appropriate scaling. For example, one might set 1km to correspond to 1 year, in which case two contemporaneous points 100 km apart are considered "as close as" two points 100 years apart but at the same spatial point. What scaling to use clearly depends on the dataset and how to query it. 

# Example: Burial rite distributions in Bronze Age Europe

One strength of ``bleiglas`` is visualization of spatiotemporal data. Here we show an example of Bronze Age burial rites as measured on radiocarbon dates from burials in Central, Northern and Northwestern Europe between 2200 and 800 calBC. Information about source data (taken from the RADON-B database [@kneiselRadonB2013]), data preparation and meaning are presented in @Schmid2019-xn. 

Bronze Age burials can be classified by two main aspects: inhumation vs. cremation (*burial type*) and flat grave vs. burial mound (*burial construction*). \autoref{fig:plot_map} is a map of burials through time for which we have some information about these variables. Each grave has a position in space (2 dimensions: coordinates) and in time (1 dimension: median calibrated radiocarbon age). For \autoref{fig:plot_3D} and \autoref{fig:plot_bleiglas} we only look at the *burial type* dimension. The burials are distributed in a three dimensional, spatiotemporal space and therefore can be subjected to voronoi tessellation with voro++. As detailed above, the outcome depends on the relative scaling of the input dimensions - for this example we choose $1\text{kilometer}=1\text{year}$, informed by some intuition about the range of human movements through time.

![Graves in the research area (rectangular frame) dating between 2200 and 800 calBC as extracted from the Radon-B database (radon-b.ufg.uni-kiel.de). The classes of the variable burial type are distinguished by colour, the ones of burial construction by shape. The map projection is EPSG:102013 and the base layer data is taken from the Natural Earth project (www.naturalearthdata.com).\label{fig:plot_map}](01_map_plot.jpeg)

![Graves in 3D space defined by two spatial (x and y in km) and a temporal (z in years calBC) dimension with voronoi polygons constructed by voro++. Each red dot represents one grave with known burial type, the fine black lines the edges of the result polygons, the rectangular wireframe box the research area now in space and time.\label{fig:plot_3D}](03_3D_plot.png)

For \autoref{fig:plot_bleiglas} we cut these polygons into 2D time slices that can be visualized in a map matrix (*bleiglas plot*). This matrix is a visually appealing and highly informative way to convey both the main trends (here: the general switch from inhumation to cremation from the Middle Bronze Age onwards) as well as how much data is available in certain areas and periods, so which resolution can be expected from a model based on this data. The example shows how bleiglas plots can be used as effective ways to communicate spatiotemporal processes derived from point patterns.

![*bleiglas plot*. Map matrix of 2D cuts through 3D voronoi polygons as presented in \autoref{fig:plot_3D}. Each subplot shows one 200 years timeslice between 2200 and 800 calBC. As each 2D polygon belongs to one input burial and data density in some areas and time periods is very low, some graves are represented in multiple subplots. Color coding and map background is as in \autoref{fig:plot_map}.\label{fig:plot_bleiglas}](04_bleiglas_plot.png)

For \autoref{fig:plot_prediction_grid} 

![.\label{fig:plot_prediction_grid}](05_prediction_grid_plot.png)

# Acknowledgements

The package benefitted from valuable comments by Joscha Gretzinger, who also suggested the name *bleiglas* (German *Bleiglasfenster* for English *Leadlight*) inspired by the appearance of the cut surface plots.

# References
