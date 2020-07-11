#include <Rcpp.h>
#include <cmath>
#include "helpfunc.h"
using namespace Rcpp;

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
//' Based on this solution:
//' \url{https://rosettacode.org/wiki/Find_the_intersection_of_a_line_with_a_plane#C.2B.2B}
//' @noRd
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
    NumericMatrix m = as<NumericMatrix>(point_a_and_point_b);
    return m;
  }
  
  // else calculate intersection point of (unlimited) line and plane
  Vector3D rv = b - a;
  Vector3D c = intersectPoint(rv, a, pn, pp);
  
  // check if intersection point exists (e.g. line parallel to plane)
  if (std::isinf(c.x) || std::isnan(c.x)) {
    return R_NilValue;
  }
  
  // ignore intersection point if the line segment is not cutting the plane
  double AB = pyth3(a.x, a.y, a.z, b.x, b.y, b.z);

  if (AB < pyth3(a.x, a.y, a.z, c.x, c.y, c.z) || AB < pyth3(b.x, b.y, b.z, c.x, c.y, c.z)) {
    return R_NilValue;
  } else {
    // else return the intersection point
    NumericVector point_c { c.x, c.y, c.z };
    point_c.attr("dim") = Dimension(1, 3);
    NumericMatrix m = as<NumericMatrix>(point_c);
    return m;
  }
}

//' Find the intersection points of multiple line segments and a plane
//' @noRd
// [[Rcpp::export]]
SEXP line_segment_plane_intersection_multi(NumericMatrix points, NumericVector plane_point, NumericVector plane_normal) {
  
  std::vector<NumericMatrix> res_multiple_segments;
  res_multiple_segments.reserve(points.nrow());
  for (int i = 0; i < points.nrow(); i++) {
    NumericVector point_a = { points(i, 0), points(i, 1), points(i, 2) };
    NumericVector point_b = { points(i, 3), points(i, 4), points(i, 5) };
    SEXP one_segment_res = line_segment_plane_intersection(point_a, point_b, plane_point, plane_normal);
    if (one_segment_res == R_NilValue) {
      continue;
    } else {
      res_multiple_segments.push_back(one_segment_res);
    }
  }
  
  return wrap(res_multiple_segments);
}
