#include <Rcpp.h>
#include "helpfunc.h"
using namespace Rcpp;

//' Check if a point is within a polygon (2D)
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

//' Check if multiple points are within a polygon (2D)
//' @noRd
// [[Rcpp::export]]
LogicalVector pnpmulti(NumericVector vertx, NumericVector verty, NumericVector testx, NumericVector testy){
  
  int n = testx.size();
  LogicalVector deci(n);
  for(int i = 0; i < n; i++) {
    deci(i) = pnp(vertx, verty, testx(i), testy(i));
  }
  
  return deci;
}