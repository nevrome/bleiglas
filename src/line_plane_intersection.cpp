#include <Rcpp.h>
using namespace Rcpp;
#include "helpfunc.h"

class Vector3D {
public:
  Vector3D(double x, double y, double z) {
    this->x = x;
    this->y = y;
    this->z = z;
  }
  
  double dot(const Vector3D& rhs) const {
    return x * rhs.x + y * rhs.y + z * rhs.z;
  }
  
  Vector3D operator-(const Vector3D& rhs) const {
    return Vector3D(x - rhs.x, y - rhs.y, z - rhs.z);
  }
  
  Vector3D operator*(double rhs) const {
    return Vector3D(rhs*x, rhs*y, rhs*z);
  }
  
  double x, y, z;
};

Vector3D intersectPoint(Vector3D rayVector, Vector3D rayPoint, Vector3D planeNormal, Vector3D planePoint) {
  Vector3D diff = rayPoint - planePoint;
  double prod1 = diff.dot(planeNormal);
  double prod2 = rayVector.dot(planeNormal);
  double prod3 = prod1 / prod2;
  return rayPoint - rayVector * prod3;
}

//' Find the intersection points of a line and a plane
//'
//' @description
//' \code{line_plane_intersection} ...
//' 
//' Based on this solution:
//' \url{https://rosettacode.org/wiki/Find_the_intersection_of_a_line_with_a_plane#C.2B.2B}
//'
//' @param point_a numeric vector. Coordinates of point A
//' @param point_b numeric vector. Coordinates of point B
//' @param plane_point numeric vector. Coordinates of plane point
//' @param plane_normal numeric vector. Plane normal vector
//'
//' @return ...
//'
//' @examples
//' line_segment_plane_intersection(
//'   c(2, 2, 0),
//'   c(2, 2, 5),
//'   c(0, 0, 10),
//'   c(0, 0, 1)
//' ) 
//' 
//' @export
// [[Rcpp::export]]
SEXP line_segment_plane_intersection(NumericVector point_a, NumericVector point_b, NumericVector plane_point, NumericVector plane_normal) {

  Vector3D rp = Vector3D(point_a[0], point_a[1], point_a[2]);  
  Vector3D rv = Vector3D(point_b[0] - point_a[0], point_b[1] - point_a[1], point_b[2] - point_a[2]);
  Vector3D pp = Vector3D(plane_point[0], plane_point[1], plane_point[2]);
  Vector3D pn = Vector3D(plane_normal[0], plane_normal[1], plane_normal[2]);
  
  // check if point_a and point_b is on the plane
  Vector3D pp_to_pa = Vector3D(pp.x - point_a[0], pp.y - point_a[1], pp.z - point_a[2]);
  Vector3D pp_to_pb = Vector3D(pp.x - point_b[0], pp.y - point_b[1], pp.z - point_b[2]);
  
  double sprod_pn_pa = pn.dot(pp_to_pa);
  double sprod_pn_pb = pn.dot(pp_to_pb);
  
  if (sprod_pn_pa == 0 && sprod_pn_pb == 0) {
    Rcout << 0 << "\n";
    return R_NilValue;
  }
  
  Vector3D point_c = intersectPoint(rv, rp, pn, pp);
  
  // dist A to B
  double AB = pyth3(point_a[0], point_a[1], point_a[2], point_b[0], point_b[1], point_b[2]);
  // dist A to C
  double AC = pyth3(point_a[0], point_a[1], point_a[2], point_c.x, point_c.y, point_c.z);
  // dist B to C
  double BC = pyth3(point_b[0], point_b[1], point_b[2], point_c.x, point_c.y, point_c.z);

  Rcout << AB << "\n";
  Rcout << AC << "\n";
  Rcout << BC << "\n";
  
  if (AB < AC || AB < BC) {
    return R_NilValue;
  } else {
    NumericVector point_c_numvec {point_c.x, point_c.y, point_c.z};
    return point_c_numvec;
  }
}
