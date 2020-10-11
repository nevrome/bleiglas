// tools::package_native_routine_registration_skeleton(".")

#include <R.h>
#include <Rinternals.h>
#include <stdlib.h> // for NULL
#include <R_ext/Rdynload.h>

/* FIXME: 
 Check these declarations against the C/Fortran source code.
 */

/* .Call calls */
extern SEXP _bleiglas_line_segment_plane_intersection(SEXP, SEXP, SEXP, SEXP);
extern SEXP _bleiglas_line_segment_plane_intersection_multi(SEXP, SEXP, SEXP);
extern SEXP _bleiglas_pnp(SEXP, SEXP, SEXP, SEXP);
extern SEXP _bleiglas_pnpmulti(SEXP, SEXP, SEXP);
extern SEXP _bleiglas_voropp_Rcpp_interface(SEXP);

static const R_CallMethodDef CallEntries[] = {
  {"_bleiglas_line_segment_plane_intersection",       (DL_FUNC) &_bleiglas_line_segment_plane_intersection,       4},
  {"_bleiglas_line_segment_plane_intersection_multi", (DL_FUNC) &_bleiglas_line_segment_plane_intersection_multi, 3},
  {"_bleiglas_pnp",                                   (DL_FUNC) &_bleiglas_pnp,                                   4},
  {"_bleiglas_pnpmulti",                              (DL_FUNC) &_bleiglas_pnpmulti,                              3},
  {"_bleiglas_voropp_Rcpp_interface",                 (DL_FUNC) &_bleiglas_voropp_Rcpp_interface,                 1},
  {NULL, NULL, 0}
};

void R_init_bleiglas(DllInfo *dll)
{
  R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
}
