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

static const R_CallMethodDef CallEntries[] = {
  {"_bleiglas_line_segment_plane_intersection", (DL_FUNC) &_bleiglas_line_segment_plane_intersection, 4},
  {NULL, NULL, 0}
};

void R_init_bleiglas(DllInfo *dll)
{
  R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
}