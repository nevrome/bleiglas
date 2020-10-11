#include <Rcpp.h>
#include <cstring>
#include "voro++.h"
using namespace voro;
using namespace Rcpp;

//' voro++ interface
//' @noRd
// [[Rcpp::export]]
SEXP voropp_Rcpp_interface(NumericVector point_a) {
  
  int i = 1;
  
  return wrap(i);
}
  