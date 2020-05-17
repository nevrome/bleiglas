// small helping funtions to be used in the c++ code

#include <Rcpp.h>
#include <math.h>
using namespace Rcpp;


#ifndef __UTILITIES__
#define __UTILITIES__

//' 3D distance (pythagoras) between two points
//'
//' @param x1 x axis value of first point
//' @param y1 y axis value of first point
//' @param z1 z axis value of first point
//' @param z2 z axis value of second point
//' @param x2 x axis value of second point
//' @param y2 y axis value of second point
//' @param z2 z axis value of second point
//'
//' @return distance value

inline double pyth3 (double x1, double y1, double z1, double x2, double y2, double z2) {
  double x = x1 - x2;
  double y = y1 - y2;
  double z = z1 - z2;
  double dist = pow(x, 2) + pow(y, 2) + pow(z, 2);
  dist = sqrt(dist);
  return dist;
}

#endif //__UTILITIES__
