// small helping funtions to be used in the c++ code

#include <Rcpp.h>
#include <math.h>
using namespace Rcpp;

#ifndef __UTILITIES__
#define __UTILITIES__

//' 3D distance (pythagoras) between two points
inline double pyth3 (double x1, double y1, double z1, double x2, double y2, double z2) {
  double x = x1 - x2;
  double y = y1 - y2;
  double z = z1 - z2;
  double dist = pow(x, 2) + pow(y, 2) + pow(z, 2);
  dist = sqrt(dist);
  return dist;
}

#endif //__UTILITIES__
