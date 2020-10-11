// Generated by using Rcpp::compileAttributes() -> do not edit by hand
// Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

#include <Rcpp.h>

using namespace Rcpp;

// line_segment_plane_intersection
SEXP line_segment_plane_intersection(NumericVector point_a, NumericVector point_b, NumericVector plane_point, NumericVector plane_normal);
RcppExport SEXP _bleiglas_line_segment_plane_intersection(SEXP point_aSEXP, SEXP point_bSEXP, SEXP plane_pointSEXP, SEXP plane_normalSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< NumericVector >::type point_a(point_aSEXP);
    Rcpp::traits::input_parameter< NumericVector >::type point_b(point_bSEXP);
    Rcpp::traits::input_parameter< NumericVector >::type plane_point(plane_pointSEXP);
    Rcpp::traits::input_parameter< NumericVector >::type plane_normal(plane_normalSEXP);
    rcpp_result_gen = Rcpp::wrap(line_segment_plane_intersection(point_a, point_b, plane_point, plane_normal));
    return rcpp_result_gen;
END_RCPP
}
// line_segment_plane_intersection_multi
SEXP line_segment_plane_intersection_multi(NumericMatrix points, NumericVector plane_point, NumericVector plane_normal);
RcppExport SEXP _bleiglas_line_segment_plane_intersection_multi(SEXP pointsSEXP, SEXP plane_pointSEXP, SEXP plane_normalSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< NumericMatrix >::type points(pointsSEXP);
    Rcpp::traits::input_parameter< NumericVector >::type plane_point(plane_pointSEXP);
    Rcpp::traits::input_parameter< NumericVector >::type plane_normal(plane_normalSEXP);
    rcpp_result_gen = Rcpp::wrap(line_segment_plane_intersection_multi(points, plane_point, plane_normal));
    return rcpp_result_gen;
END_RCPP
}
// pnp
bool pnp(NumericVector vertx, NumericVector verty, float testx, float testy);
RcppExport SEXP _bleiglas_pnp(SEXP vertxSEXP, SEXP vertySEXP, SEXP testxSEXP, SEXP testySEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< NumericVector >::type vertx(vertxSEXP);
    Rcpp::traits::input_parameter< NumericVector >::type verty(vertySEXP);
    Rcpp::traits::input_parameter< float >::type testx(testxSEXP);
    Rcpp::traits::input_parameter< float >::type testy(testySEXP);
    rcpp_result_gen = Rcpp::wrap(pnp(vertx, verty, testx, testy));
    return rcpp_result_gen;
END_RCPP
}
// pnpmulti
NumericVector pnpmulti(List polygons, NumericVector testx, NumericVector testy);
RcppExport SEXP _bleiglas_pnpmulti(SEXP polygonsSEXP, SEXP testxSEXP, SEXP testySEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< List >::type polygons(polygonsSEXP);
    Rcpp::traits::input_parameter< NumericVector >::type testx(testxSEXP);
    Rcpp::traits::input_parameter< NumericVector >::type testy(testySEXP);
    rcpp_result_gen = Rcpp::wrap(pnpmulti(polygons, testx, testy));
    return rcpp_result_gen;
END_RCPP
}
// voropp_Rcpp_interface
SEXP voropp_Rcpp_interface(NumericVector point_a);
RcppExport SEXP _bleiglas_voropp_Rcpp_interface(SEXP point_aSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< NumericVector >::type point_a(point_aSEXP);
    rcpp_result_gen = Rcpp::wrap(voropp_Rcpp_interface(point_a));
    return rcpp_result_gen;
END_RCPP
}
