#include <Rcpp.h>
#include <cstring>
#include "voro++0.4.6/voro++.h"
using namespace voro;
using namespace Rcpp;

// This function returns a random floating point number between 0 and 1
double rnd() {return double(rand())/RAND_MAX;}

//' voro++ interface
//' @noRd
// [[Rcpp::export]]
SEXP voropp_Rcpp_interface(NumericVector point_a) {
  
  double x,y,z,rsq,r;
  voronoicell v;
        
  // Initialize the Voronoi cell to be a cube of side length 2, centered
  // on the origin
  v.init(-1,1,-1,1,-1,1);
  
  // Cut the cell by 250 random planes which are all a distance 1 away
  // from the origin, to make an approximation to a sphere
  for(int i=0;i<250;i++) {
           x=2*rnd()-1;
           y=2*rnd()-1;
           z=2*rnd()-1;
           rsq=x*x+y*y+z*z;
           if(rsq>0.01&&rsq<1) {
                     r=1/sqrt(rsq);x*=r;y*=r;z*=r;
                     v.plane(x,y,z,1);
             }
   }
  
   // Output the Voronoi cell to a file, in the gnuplot format
  v.draw_gnuplot(0,0,0,"single_cell.gnu");
  
  int i = 1;
  
  return wrap(i);
}
  