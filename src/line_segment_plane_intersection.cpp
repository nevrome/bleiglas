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

//' Find the intersection points of a line segment and a plane
//'
//' @description
//' \code{line_segment_plane_intersection} ...
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

  Vector3D a = Vector3D(point_a[0], point_a[1], point_a[2]);
  Vector3D b = Vector3D(point_b[0], point_b[1], point_b[2]);
  Vector3D pp = Vector3D(plane_point[0], plane_point[1], plane_point[2]);
  Vector3D pn = Vector3D(plane_normal[0], plane_normal[1], plane_normal[2]);
  
  // check if point_a and point_b is on the plane
  Vector3D pp_to_pa = pp - a;
  Vector3D pp_to_pb = pp - b;
  
  double sprod_pn_pa = pn.dot(pp_to_pa);
  double sprod_pn_pb = pn.dot(pp_to_pb);
  
  if (sprod_pn_pa == 0 && sprod_pn_pb == 0) {
    // return numeric matrix with the input points in this case 
    NumericVector point_a_and_point_b { a.x, b.x, a.y, b.y, a.z, b.z };
    point_a_and_point_b.attr("dim") = Dimension(2, 3);
    return point_a_and_point_b;
  }
  
  // else calculate intersection point of (unlimited) line and plane
  Vector3D rv = b - a;
  Vector3D c = intersectPoint(rv, a, pn, pp);
  
  // check if intersection point exists (e.g. line parallel to plane)
  if (isinf(c.x) || isnan(c.x)) {
    return R_NilValue;
  }
  
  // ignore intersection point if the line segment is not cutting the plane
  double AB = pyth3(a.x, a.y, a.z, b.x, b.y, b.z);

  if (AB < pyth3(a.x, a.y, a.z, c.x, c.y, c.z) || AB < pyth3(b.x, b.y, b.z, c.x, c.y, c.z)) {
    return R_NilValue;
  } else {
    // else return the intersection point
    NumericVector point_c_numvec { c.x, c.y, c.z };
    return point_c_numvec;
  }
}
