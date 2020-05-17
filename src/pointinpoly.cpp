#include <Rcpp.h>
#include "helpfunc.h"
using namespace Rcpp;

//' Check if a point is within a polygon (2D)
//'
//' @description
//' \code{pnp} is able to determine if a point is within a polygon in 2D space.
//' The polygon is described by its corner points. The points must be in a correct
//' drawing order.
//'
//' Based on this solution:
//' Copyright (c) 1970-2003, Wm. Randolph Franklin
//' \url{http://wrf.ecse.rpi.edu/pmwiki/pmwiki.php/Main/Software#toc24}
//'
//' @details
//' For discussion see: \url{http://stackoverflow.com/questions/217578/how-can-i-determine-whether-a-2d-point-is-within-a-polygon/2922778#2922778}
//'
//' @param vertx vector of x axis values of polygon corner points
//' @param verty vector of y axis values of polygon corner points
//' @param testx x axis value of point of interest
//' @param testy y axis value of point of interest
//'
//' @return boolean value - TRUE, if the point is within the polygon. Otherwise FALSE.
//'
//' @family pnpfuncs
//'
//' @examples
//' df <- data.frame(
//'   x = c(1,1,2,2),
//'   y = c(1,2,1,2)
//' )
//'
//' pnp(df$x, df$y, 1.5, 1.5)
//' pnp(df$x, df$y, 2.5, 2.5)
//'
//' # caution: false-negatives in edge-cases:
//' pnp(df$x, df$y, 2, 1.5)
//'
//' @export
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

//' Check if multiple points are within a polygon (2D)
//'
//' @description
//' \code{pnpmulti} works as \code{\link{pnp}} but for multiple points.
//'
//' @param vertx vector of x axis values of polygon corner points
//' @param verty vector of y axis values of polygon corner points
//' @param testx vector of x axis values of points of interest
//' @param testy vector of y axis values of points of interest
//'
//' @return vector with boolean values - TRUE, if the respective point is within the polygon.
//' Otherwise FALSE.
//'
//' @examples
//' polydf <- data.frame(
//'   x = c(1,1,2,2),
//'   y = c(1,2,1,2)
//' )
//'
//' testdf <- data.frame(
//'   x = c(1.5, 2.5),
//'   y = c(1.5, 2.5)
//' )
//'
//' pnpmulti(polydf$x, polydf$y, testdf$x, testdf$y)
//'
//' @family pnpfuncs
//'
//' @export
// [[Rcpp::export]]
LogicalVector pnpmulti(NumericVector vertx, NumericVector verty, NumericVector testx, NumericVector testy){
  
  int n = testx.size();
  LogicalVector deci(n);
  for(int i = 0; i < n; i++) {
    deci(i) = pnp(vertx, verty, testx(i), testy(i));
  }
  
  return deci;
}