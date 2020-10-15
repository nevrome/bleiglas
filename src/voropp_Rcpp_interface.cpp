#include <Rcpp.h>
#include <cstring>
#include "voro++0.4.6/voro++.h"
using namespace voro;
using namespace Rcpp;

enum blocks_mode {
  none,
  length_scale,
  specified
};

// A maximum allowed number of regions, to prevent enormous amounts of memory
// being allocated
const int max_regions=16777216;

// This message is displayed if the user requests version information
void version_message() {
  puts("Voro++ version 0.4.5 (July 27th 2012)");
}

// Prints an error message. This is called when the program is unable to make
// sense of the command-line options.
void error_message() {
  fputs("voro++: Unrecognized command-line options; type \"voro++ -h\" for more\ninformation.\n",stderr);
}

// Carries out the Voronoi computation and outputs the results to the requested
// files
template<class c_loop,class c_class>
void cmd_line_output(c_loop &vl,c_class &con,const char* format,FILE* outfile,FILE* gnu_file,FILE* povp_file,FILE* povv_file,bool verbose,double &vol,int &vcc,int &tp) {
  int pid,ps=con.ps;double x,y,z,r;
  if(con.contains_neighbor(format)) {
    voronoicell_neighbor c;
    if(vl.start()) do if(con.compute_cell(c,vl)) {
      vl.pos(pid,x,y,z,r);
      if(outfile!=NULL) c.output_custom(format,pid,x,y,z,r,outfile);
      if(gnu_file!=NULL) c.draw_gnuplot(x,y,z,gnu_file);
      if(povp_file!=NULL) {
        fprintf(povp_file,"// id %d\n",pid);
        if(ps==4) fprintf(povp_file,"sphere{<%g,%g,%g>,%g}\n",x,y,z,r);
        else fprintf(povp_file,"sphere{<%g,%g,%g>,s}\n",x,y,z);
      }
      if(povv_file!=NULL) {
        fprintf(povv_file,"// cell %d\n",pid);
        c.draw_pov(x,y,z,povv_file);
      }
      if(verbose) {vol+=c.volume();vcc++;}
    } while(vl.inc());
  } else {
    voronoicell c;
    if(vl.start()) do if(con.compute_cell(c,vl)) {
      vl.pos(pid,x,y,z,r);
      if(outfile!=NULL) c.output_custom(format,pid,x,y,z,r,outfile);
      if(gnu_file!=NULL) c.draw_gnuplot(x,y,z,gnu_file);
      if(povp_file!=NULL) {
        fprintf(povp_file,"// id %d\n",pid);
        if(ps==4) fprintf(povp_file,"sphere{<%g,%g,%g>,%g}\n",x,y,z,r);
        else fprintf(povp_file,"sphere{<%g,%g,%g>,s}\n",x,y,z);
      }
      if(povv_file!=NULL) {
        fprintf(povv_file,"// cell %d\n",pid);
        c.draw_pov(x,y,z,povv_file);
      }
      if(verbose) {vol+=c.volume();vcc++;}
    } while(vl.inc());
  }
  if(verbose) tp=con.total_particles();
}

//' voro++ interface
//' @noRd
// [[Rcpp::export]]
SEXP voropp_Rcpp_interface(StringVector argv) {
  
  int argc = argv.length();
  
  Rcout << argc << std::endl;
  
  // int i = 1;
  // 
  // return wrap(i);

  int i=1,j=-7,custom_output=0,nx,ny,nz,init_mem(8);
  double ls=0;
  blocks_mode bm=none;
  bool gnuplot_output=false,povp_output=false,povv_output=false,polydisperse=false;
  bool xperiodic=false,yperiodic=false,zperiodic=false,ordered=false,verbose=false;
  pre_container *pcon=NULL;pre_container_poly *pconp=NULL;
  wall_list wl;
  
  // If there aren't enough command-line arguments, then bail out
  // with an error.
  if(argc<7) {
    error_message();
    return wrap(VOROPP_CMD_LINE_ERROR);
  }
  
  // We have enough arguments. Now start searching for command-line
  // options.
  while(i<argc-7) {
    if(strcmp(argv[i],"-c")==0) {
      if(i>=argc-8) {error_message();wl.deallocate();return wrap(VOROPP_CMD_LINE_ERROR);}
      if(custom_output==0) {
        custom_output=++i;
      } else {
        fputs("voro++: multiple custom output strings detected\n",stderr);
        wl.deallocate();
        return wrap(VOROPP_CMD_LINE_ERROR);
      }
    } else if(strcmp(argv[i],"-g")==0) {
      gnuplot_output=true;
    } else if(strcmp(argv[i],"-l")==0) {
      if(i>=argc-8) {error_message();wl.deallocate();return wrap(VOROPP_CMD_LINE_ERROR);}
      if(bm!=none) {
        fputs("voro++: Conflicting options about grid setup (-l/-n)\n",stderr);
        wl.deallocate();
        return wrap(VOROPP_CMD_LINE_ERROR);
      }
      bm=length_scale;
      i++;ls=atof(argv[i]);
    } else if(strcmp(argv[i],"-m")==0) {
      i++;init_mem=atoi(argv[i]);
    } else if(strcmp(argv[i],"-n")==0) {
      if(i>=argc-10) {error_message();wl.deallocate();return wrap(VOROPP_CMD_LINE_ERROR);}
      if(bm!=none) {
        fputs("voro++: Conflicting options about grid setup (-l/-n)\n",stderr);
        wl.deallocate();
        return wrap(VOROPP_CMD_LINE_ERROR);
      }
      bm=specified;
      i++;
      nx=atoi(argv[i++]);
      ny=atoi(argv[i++]);
      nz=atoi(argv[i]);
      if(nx<=0||ny<=0||nz<=0) {
        fputs("voro++: Computational grid specified with -n must be greater than one\n"
                "in each direction\n",stderr);
        wl.deallocate();
        return wrap(VOROPP_CMD_LINE_ERROR);
      }
    } else if(strcmp(argv[i],"-o")==0) {
      ordered=true;
    } else if(strcmp(argv[i],"-p")==0) {
      xperiodic=yperiodic=zperiodic=true;
    } else if(strcmp(argv[i],"-px")==0) {
      xperiodic=true;
    } else if(strcmp(argv[i],"-py")==0) {
      yperiodic=true;
    } else if(strcmp(argv[i],"-pz")==0) {
      zperiodic=true;
    } else if(strcmp(argv[i],"-r")==0) {
      polydisperse=true;
    } else if(strcmp(argv[i],"-v")==0) {
      verbose=true;
    } else if(strcmp(argv[i],"--version")==0) {
      version_message();
      wl.deallocate();
      return 0;
    } else if(strcmp(argv[i],"-wb")==0) {
      if(i>=argc-13) {error_message();wl.deallocate();return wrap(VOROPP_CMD_LINE_ERROR);}
      i++;
      double w0=atof(argv[i++]),w1=atof(argv[i++]);
      double w2=atof(argv[i++]),w3=atof(argv[i++]);
      double w4=atof(argv[i++]),w5=atof(argv[i]);
      wl.add_wall(new wall_plane(-1,0,0,-w0,j));j--;			
      wl.add_wall(new wall_plane(1,0,0,w1,j));j--;			
      wl.add_wall(new wall_plane(0,-1,0,-w2,j));j--;			
      wl.add_wall(new wall_plane(0,1,0,w3,j));j--;			
      wl.add_wall(new wall_plane(0,0,-1,-w4,j));j--;			
      wl.add_wall(new wall_plane(0,0,1,w5,j));j--;			
    } else if(strcmp(argv[i],"-ws")==0) {
      if(i>=argc-11) {error_message();wl.deallocate();return wrap(VOROPP_CMD_LINE_ERROR);}
      i++;
      double w0=atof(argv[i++]),w1=atof(argv[i++]);
      double w2=atof(argv[i++]),w3=atof(argv[i]);
      wl.add_wall(new wall_sphere(w0,w1,w2,w3,j));
      j--;
    } else if(strcmp(argv[i],"-wp")==0) {
      if(i>=argc-11) {error_message();wl.deallocate();return wrap(VOROPP_CMD_LINE_ERROR);}
      i++;
      double w0=atof(argv[i++]),w1=atof(argv[i++]);
      double w2=atof(argv[i++]),w3=atof(argv[i]);
      wl.add_wall(new wall_plane(w0,w1,w2,w3,j));
      j--;
    } else if(strcmp(argv[i],"-wc")==0) {
      if(i>=argc-14) {error_message();wl.deallocate();return wrap(VOROPP_CMD_LINE_ERROR);}
      i++;
      double w0=atof(argv[i++]),w1=atof(argv[i++]);
      double w2=atof(argv[i++]),w3=atof(argv[i++]);
      double w4=atof(argv[i++]),w5=atof(argv[i++]);
      double w6=atof(argv[i]);
      wl.add_wall(new wall_cylinder(w0,w1,w2,w3,w4,w5,w6,j));
      j--;
    } else if(strcmp(argv[i],"-wo")==0) {
      if(i>=argc-14) {error_message();wl.deallocate();return wrap(VOROPP_CMD_LINE_ERROR);}
      i++;
      double w0=atof(argv[i++]),w1=atof(argv[i++]);
      double w2=atof(argv[i++]),w3=atof(argv[i++]);
      double w4=atof(argv[i++]),w5=atof(argv[i++]);
      double w6=atof(argv[i]);
      wl.add_wall(new wall_cone(w0,w1,w2,w3,w4,w5,w6,j));
      j--;
    } else if(strcmp(argv[i],"-y")==0) {
      povp_output=povv_output=true;
    } else if(strcmp(argv[i],"-yp")==0) {
      povp_output=true;
    } else if(strcmp(argv[i],"-yv")==0) {
      povv_output=true;
    } else {
      wl.deallocate();
      error_message();
      return wrap(VOROPP_CMD_LINE_ERROR);
    }
    i++;
  }
  
  // Check the memory guess is positive
  if(init_mem<=0) {
    fputs("voro++: The memory allocation must be positive\n",stderr);
    wl.deallocate();
    return wrap(VOROPP_CMD_LINE_ERROR);
  }
  
  // Read in the dimensions of the test box, and estimate the number of
  // boxes to divide the region up into
  double ax=atof(argv[i]),bx=atof(argv[i+1]);
  double ay=atof(argv[i+2]),by=atof(argv[i+3]);
  double az=atof(argv[i+4]),bz=atof(argv[i+5]);
  
  // Check that for each coordinate, the minimum value is smaller
  // than the maximum value
  if(bx<ax) {
    fputs("voro++: Minimum x coordinate exceeds maximum x coordinate\n",stderr);
    wl.deallocate();
    return wrap(VOROPP_CMD_LINE_ERROR);
  }
  if(by<ay) {
    fputs("voro++: Minimum y coordinate exceeds maximum y coordinate\n",stderr);
    wl.deallocate();
    return wrap(VOROPP_CMD_LINE_ERROR);
  }
  if(bz<az) {
    fputs("voro++: Minimum z coordinate exceeds maximum z coordinate\n",stderr);
    wl.deallocate();
    return wrap(VOROPP_CMD_LINE_ERROR);
  }
  
  if(bm==none) {
    if(polydisperse) {
      pconp=new pre_container_poly(ax,bx,ay,by,az,bz,xperiodic,yperiodic,zperiodic);
      pconp->import(argv[i+6]);
      pconp->guess_optimal(nx,ny,nz);
    } else {
      pcon=new pre_container(ax,bx,ay,by,az,bz,xperiodic,yperiodic,zperiodic);
      pcon->import(argv[i+6]);
      pcon->guess_optimal(nx,ny,nz);
    }
  } else {
    double nxf,nyf,nzf;
    if(bm==length_scale) {
      
      // Check that the length scale is positive and
      // reasonably large
      if(ls<tolerance) {
        fputs("voro++: ",stderr);
        if(ls<0) {
          fputs("The length scale must be positive\n",stderr);
        } else {
          fprintf(stderr,"The length scale is smaller than the safe limit of %g. Either\nincrease the particle length scale, or recompile with a different limit.\n",tolerance);
        }
        wl.deallocate();
        return wrap(VOROPP_CMD_LINE_ERROR);
      }
      ls=0.6/ls;
      nxf=(bx-ax)*ls+1;
      nyf=(by-ay)*ls+1;
      nzf=(bz-az)*ls+1;
      
      nx=int(nxf);ny=int(nyf);nz=int(nzf);
    } else {
      nxf=nx;nyf=ny;nzf=nz;
    }
    
    // Compute the number regions based on the length scale
    // provided. If the total number exceeds a cutoff then bail
    // out, to prevent making a massive memory allocation. Do this
    // test using floating point numbers, since huge integers could
    // potentially wrap around to negative values.
    if(nxf*nyf*nzf>max_regions) {
      fprintf(stderr,"voro++: Number of computational blocks exceeds the maximum allowed of %d.\n"
                "Either increase the particle length scale, or recompile with an increased\nmaximum.",max_regions);
      wl.deallocate();
      return wrap(VOROPP_MEMORY_ERROR);
    }
  }
  
  // Check that the output filename is a sensible length
  int flen=strlen(argv[i+6]);
  if(flen>4096) {
    fputs("voro++: Filename too long\n",stderr);
    wl.deallocate();
    return wrap(VOROPP_CMD_LINE_ERROR);
  }
  
  // Open files for output
  char *buffer=new char[flen+7];
  sprintf(buffer,"%s.vol",argv[i+6]);
  FILE *outfile=safe_fopen(buffer,"w"),*gnu_file,*povp_file,*povv_file;
  if(gnuplot_output) {
    sprintf(buffer,"%s.gnu",argv[i+6]);
    gnu_file=safe_fopen(buffer,"w");
  } else gnu_file=NULL;
  if(povp_output) {
    sprintf(buffer,"%s_p.pov",argv[i+6]);
    povp_file=safe_fopen(buffer,"w");
  } else povp_file=NULL;
  if(povv_output) {
    sprintf(buffer,"%s_v.pov",argv[i+6]);
    povv_file=safe_fopen(buffer,"w");
  } else povv_file=NULL;
  delete [] buffer;
  
  const char *c_str=(custom_output==0?(polydisperse?"%i %q %v %r":"%i %q %v"):argv[custom_output]);
  
  // Now switch depending on whether polydispersity was enabled, and
  // whether output ordering is requested
  double vol=0;int tp=0,vcc=0;
  if(polydisperse) {
    if(ordered) {
      particle_order vo;
      container_poly con(ax,bx,ay,by,az,bz,nx,ny,nz,xperiodic,yperiodic,zperiodic,init_mem);
      con.add_wall(wl);
      if(bm==none) {
        pconp->setup(vo,con);delete pconp;
      } else con.import(vo,argv[i+6]);
      
      c_loop_order vlo(con,vo);
      cmd_line_output(vlo,con,c_str,outfile,gnu_file,povp_file,povv_file,verbose,vol,vcc,tp);
    } else {
      container_poly con(ax,bx,ay,by,az,bz,nx,ny,nz,xperiodic,yperiodic,zperiodic,init_mem);
      con.add_wall(wl);
      
      if(bm==none) {
        pconp->setup(con);delete pconp;
      } else con.import(argv[i+6]);
      
      c_loop_all vla(con);
      cmd_line_output(vla,con,c_str,outfile,gnu_file,povp_file,povv_file,verbose,vol,vcc,tp);
    }
  } else {
    if(ordered) {
      particle_order vo;
      container con(ax,bx,ay,by,az,bz,nx,ny,nz,xperiodic,yperiodic,zperiodic,init_mem);
      con.add_wall(wl);
      if(bm==none) {
        pcon->setup(vo,con);delete pcon;
      } else con.import(vo,argv[i+6]);
      
      c_loop_order vlo(con,vo);
      cmd_line_output(vlo,con,c_str,outfile,gnu_file,povp_file,povv_file,verbose,vol,vcc,tp);
    } else {
      container con(ax,bx,ay,by,az,bz,nx,ny,nz,xperiodic,yperiodic,zperiodic,init_mem);
      con.add_wall(wl);
      if(bm==none) {
        pcon->setup(con);delete pcon;
      } else con.import(argv[i+6]);
      c_loop_all vla(con);
      cmd_line_output(vla,con,c_str,outfile,gnu_file,povp_file,povv_file,verbose,vol,vcc,tp);
    }
  }
  
  // Print information if verbose output requested
  if(verbose) {
    printf("Container geometry        : [%g:%g] [%g:%g] [%g:%g]\n"
             "Computational grid size   : %d by %d by %d (%s)\n"
             "Filename                  : %s\n"
             "Output string             : %s%s\n",ax,bx,ay,by,az,bz,nx,ny,nz,
             bm==none?"estimated from file":(bm==length_scale?
                                               "estimated using length scale":"directly specified"),
                                               argv[i+6],c_str,custom_output==0?" (default)":"");
    printf("Total imported particles  : %d (%.2g per grid block)\n"
             "Total V. cells computed   : %d\n"
             "Total container volume    : %g\n"
             "Total V. cell volume      : %g\n",tp,((double) tp)/(nx*ny*nz),
             vcc,(bx-ax)*(by-ay)*(bz-az),vol);
  }
  
  // Close output files
  fclose(outfile);
  if(gnu_file!=NULL) fclose(gnu_file);
  if(povp_file!=NULL) fclose(povp_file);
  if(povv_file!=NULL) fclose(povv_file);
  return 0;
}
  
  