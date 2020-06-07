---
title: 'bleiglas: An R package for 3D tessellation with voro++ and related analysis operations'
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

The open source software library [voro++](http://math.lbl.gov/voro++) [@Rycroft2009-rp] allows fast calculation of Voronoi diagrams in three dimensions. Voronoi diagrams are a special form of tessellation (i.e. filling space with geometric shapes without gaps or overlaps), where each polygon is defined as the region consisting of all points closest to one particular seed point. Imagine a volume in three dimensional space and an arbitrary distribution of unique points within this volume. voro++ creates a polygon around each point so that everything within this polygon is closest to the corresponding point and farther away from the other starting points.

Voronoi tessellation has useful applications in all kinds of scientific contexts spanning astronomy (e.g. @Paranjape2020-sg) material science (e.g. @Tsuru2020-ep) or geography (e.g. @Liu2019-fw). From the point of view of computational and landscape archaeology delaunay triangulation and voronoi diagrams were as well applied as tools for data analysis [@Nakoinz2016-bq], but so far to our knowledge limited to an entirely spatial 2D perspective. 3D tessellation could as well be employed here to add a third dimension: most intriguingly a temporal one. This could allow for new methods of spatiotemporal data analysis and visualization as demonstrated in the example below.

The ``bleiglas`` R package serves as an R interface to the voro++ command line tool. It adds a number of utility functions for particular data manipulation applications, including but not limited to automatic cutting of the 3D voro++ output for subsequent visualisation and grid sampling for position and value uncertainty mitigation. The relevant workflows are explained below. Although we wrote this package for our own needs in archaeology and archaeogenetics, the code is by no means restricted to data from these fields, just as voronoi tessellation is a subject agnostic method with a huge range of use-cases.

# Core functionality

``bleiglas`` provides the `tessellate()` function which is a a command line utility wrapper for voro++. It requires the voro++ cmd tool to be installed locally. `bleiglas::tessellate()` takes the input points in the form of a data.frame with an integer ID- and three numeric coordinate columns. Additional voro++ [options](http://math.lbl.gov/voro++/doc/cmd.html) can be set with a character argument `options` and only the [output format definition](http://math.lbl.gov/voro++/doc/custom.html) (`-c`) is lifted to an extra character argument `output_definition`. `bleiglas::tessellate()` returns a character vector containing the raw output of voro++ with one vector element corresponding to one row. Depending on the structure of this raw output different parsing functions are required to transform it to an useful R objects. At the moment ``bleiglas`` only provides one such parsing function: `bleiglas::read_polygon_edges()`. It is adjusted to read data produced with the voro++ output format string `%i*%P*%t`, which returns polygon edge coordinates necessary for the default ``bleiglas`` workflow illustrated in the example below. Future versions of the package may include other parsing functions for different pipelines.

# Example: Burial rite distributions in Bronze Age Europe

# Acknowledgements

The package benefitted from valuable input by Joscha Gretzinger.

# References
