#include <Rcpp.h>
#include "helpfunc.h"
using namespace Rcpp;

//' Check if a point is within a polygon (2D)
//' Based on this solution:
//' Copyright (c) 1970-2003, Wm. Randolph Franklin
//' \url{http://wrf.ecse.rpi.edu/pmwiki/pmwiki.php/Main/Software#toc24}
//' For discussion see: \url{http://stackoverflow.com/questions/217578/how-can-i-determine-whether-a-2d-point-is-within-a-polygon/2922778#2922778}
//' @noRd
// [[Rcpp::export]]
bool pnp(NumericVector vertx, NumericVector verty, float testx, float testy) {
  
  int nvert = vertx.size();
  bool c = FALSE;
  int i, j = 0;
  for (i = 0, j = nvert-1; i < nvert; j = i++) {
    if ( ((verty[i]>testy) != (verty[j]>testy)) &&
         (testx < (vertx[j]-vertx[i]) * (testy-verty[i]) / (verty[j]-verty[i]) + vertx[i]) )
      c = !c;
  }
  
  return c;
}

//' Check if multiple points are within multiple polygons (2D)
//' @noRd
// [[Rcpp::export]]
NumericVector pnpmulti(List polygons, NumericVector testx, NumericVector testy){

  int number_of_points = testx.size();
  int number_of_polygons = polygons.size();    
    
  NumericVector pos_poly (testx.length());
  
  for(int i = 0; i < number_of_points; i++) {
    for(int j = 0; j < number_of_polygons; j++) {
      DataFrame polygon = as<Rcpp::DataFrame>(polygons[j]);
      bool is_in_this_polygon = pnp(polygon[0], polygon[1], testx(i), testy(i));
      if (is_in_this_polygon) {
        pos_poly[i] = j + 1;
      }
    }
  }
  
  return pos_poly;
}

