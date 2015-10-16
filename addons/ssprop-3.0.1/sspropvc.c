/*  File:           sspropvc.c
 *  Authors:        Afrouz Azari (afrouz@umd.edu)
 *                  Ross A. Pleban (rapleban@ncsu.edu)
 *                  Reza Salem (rsalem@umd.edu)
 *                  Thomas E. Murphy (tem@umd.edu)
 *
 *  Created:        1/17/2001
 *  Modified:       8/18/2006
 *  Version:        3.0
 *  Description:    This file solves the coupled nonlinear
 *                  Schrodinger equations for propagation in an
 *                  optical fiber, using the split-step Fourier
 *                  method.  The routine is compiled as a Matlab
 *                  MEX function that can be invoked directly
 *                  from Matlab.  
 */


/* 
 * USAGE:
 * [u1x,u1y] = sspropvc(u0x,u0y,dt,dz,nz,alphaa,alphab,betapa,betapb,gamma);
 * [u1x,u1y] = sspropvc(u0x,u0y,dt,dz,nz,alphaa,alphab,betapa,betapb,gamma,psp);
 * [u1x,u1y] = sspropvc(u0x,u0y,dt,dz,nz,alphaa,alphab,betapa,betapb,gamma,psp,method);
 * [u1x,u1y] = sspropvc(u0x,u0y,dt,dz,nz,alphaa,alphab,betapa,betapb,gamma,psp,method,maxiter;
 * [u1x,u1y] = sspropvc(u0x,u0y,dt,dz,nz,alphaa,alphab,betapa,betapb,gamma,psp,method,maxiter,tol);
 * sspropvc -option
 *
 * OPTIONS:   (i.e. sspropvc -savewisdom )
 *  -savewisdom
 *  -forgetwisdom
 *  -loadwisdom
 *  -patient
 *  -exhaustive
 *  -measure
 *  -estimate
 */


/*****************************************************************

    Copyright 2006, Thomas E. Murphy

    This file is part of SSPROP.

    SSPROP is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version
    2 of the License, or (at your option) any later version.

    SSPROP is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public
    License along with SSPROP; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
    02111-1307 USA

*****************************************************************/

#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "fftw3.h"
#include "mex.h"

#ifdef SINGLEPREC

#define REAL float
#define COMPLEX fftwf_complex
#define PLAN fftwf_plan
#define MAKE_PLAN fftwf_plan_dft_1d
#define DESTROY_PLAN fftwf_destroy_plan
#define EXECUTE fftwf_execute
#define IMPORT_WISDOM fftwf_import_wisdom_from_file
#define EXPORT_WISDOM fftwf_export_wisdom_to_file
#define FORGET_WISDOM fftwf_forget_wisdom
#define WISFILENAME "fftwf-wisdom.dat"

#else

#define REAL double
#define COMPLEX fftw_complex
#define PLAN fftw_plan
#define MAKE_PLAN fftw_plan_dft_1d
#define DESTROY_PLAN fftw_destroy_plan
#define EXECUTE fftw_execute
#define IMPORT_WISDOM fftw_import_wisdom_from_file
#define EXPORT_WISDOM fftw_export_wisdom_to_file
#define FORGET_WISDOM fftw_forget_wisdom
#define WISFILENAME "fftw-wisdom.dat"

#endif

#define abs2(x) ((*x)[0] * (*x)[0] + (*x)[1] * (*x)[1])
#define round(x) ((int)(x+0.5))
#define pi 3.1415926535897932384626433832795028841972

static int firstcall = 1;       /* =1 when sspropvc first invoked */
int allocated = 0;              /* =1 when memory is allocated */
static int method = FFTW_PATIENT;	/* planner method */

void sspropvc_save_wisdom();
void sspropvc_load_wisdom();
void cscale(COMPLEX*,COMPLEX*,COMPLEX*,COMPLEX*,REAL,int);
void rotate_coord(COMPLEX*,COMPLEX*,const mxArray*,const mxArray*,REAL,REAL,int);
void compute_w(REAL*,REAL,int);
void compute_hahb(COMPLEX*,COMPLEX*,const mxArray*,const mxArray*,const mxArray*,
                  const mxArray*,REAL*,REAL,int);
void compute_H(COMPLEX*,COMPLEX*,COMPLEX*,COMPLEX*,COMPLEX*,COMPLEX*,
               REAL,REAL,int);
void prop_linear_ellipt(COMPLEX* uZa, COMPLEX* uZb, COMPLEX* ha,
                        COMPLEX* hb,COMPLEX* u0a,COMPLEX* u0b,int nt);
void prop_linear_circ(COMPLEX*,COMPLEX*,COMPLEX*,COMPLEX*,COMPLEX*,
                      COMPLEX*,COMPLEX*,COMPLEX*,int);
void nonlinear_propagate(COMPLEX*,COMPLEX*,COMPLEX*,COMPLEX*,COMPLEX*,
                         COMPLEX*,COMPLEX*,COMPLEX*,REAL,REAL,REAL,int);
int is_converged(COMPLEX*,COMPLEX*,COMPLEX*,COMPLEX*,REAL,int);
void inv_rotate_coord(mxArray*,mxArray*,COMPLEX*,COMPLEX*,
                      REAL,REAL,int);
void mexFunction(int, mxArray* [], int, const mxArray* []);


/* Saves the wisdom data to a file specified by WISFILENAME */
void sspropvc_save_wisdom() 
{ 
  FILE *wisfile;
  
  wisfile = fopen(WISFILENAME, "w");
  if (wisfile) {
    mexPrintf("Exporting FFTW wisdom (file = %s).\n", WISFILENAME);
    EXPORT_WISDOM(wisfile);
    fclose(wisfile);
  } 
}


/* Loads the wisdom file into memory specified by WISFILENAME.  The 
 * program automatically attempts to load the wisdom on the first call */
void sspropvc_load_wisdom() 
{ 
  FILE *wisfile;
  
  wisfile = fopen(WISFILENAME, "r");
  if (wisfile) {
	mexPrintf("Importing FFTW wisdom (file = %s).\n", WISFILENAME);
	if (!IMPORT_WISDOM(wisfile)) {
      fclose(wisfile);
      mexErrMsgTxt("could not import wisdom.");
    }
    else
	  fclose(wisfile);
  }
}


/* Assigns a = factor*b  and  x = factor*y  for length nt vectors */
void cscale(COMPLEX* a,COMPLEX* b,COMPLEX* x,COMPLEX* y,REAL factor,int nt)
{
  int jj;
  
  for (jj = 0; jj < nt; jj++) {
    a[jj][0] = factor*b[jj][0];
    a[jj][1] = factor*b[jj][1];
    x[jj][0] = factor*y[jj][0];
    x[jj][1] = factor*y[jj][1];
  }
}


/* Rotates input to the coordinate system defined by chi & psi 
 *
 * Elliptical MATLAB equivalent:
 *   u0a = ( cos(psi)*cos(chi) - j*sin(psi)*sin(chi))*u0x + ...
 *         ( sin(psi)*cos(chi) + j*cos(psi)*sin(chi))*u0y;
 *   u0b = (-sin(psi)*cos(chi) + j*cos(psi)*sin(chi))*u0x + ...
 *         ( cos(psi)*cos(chi) + j*sin(psi)*sin(chi))*u0y;
 * 
 * Circular MATLAB equivalent (when chi = pi/4 and psi = 0):
 *   u0a = (1/sqrt(2)).*(u0x + j*u0y);
 *   u0b = (1/sqrt(2)).*(j*u0x + u0y);
 */
void rotate_coord(COMPLEX* u0a, COMPLEX* u0b,const mxArray* ux, const mxArray* uy,
                  REAL chi, REAL psi, int nt) 
{ 
  REAL cc = (REAL) (cos(psi)*cos(chi));
  REAL ss = (REAL) (sin(psi)*sin(chi));
  REAL sc = (REAL) (sin(psi)*cos(chi));
  REAL cs = (REAL) (cos(psi)*sin(chi));
  int jj;
  if (mxIsComplex(ux) && mxIsComplex(uy))
    for(jj = 0; jj < nt; jj++) {
      u0a[jj][0] = cc*mxGetPr(ux)[jj] + ss* mxGetPi(ux)[jj] + 
                   sc*mxGetPr(uy)[jj] - cs*mxGetPi(uy)[jj];
      u0a[jj][1] = cc*mxGetPi(ux)[jj] - ss*mxGetPr(ux)[jj] + 
                   sc*mxGetPi(uy)[jj] + cs*mxGetPr(uy)[jj];
      u0b[jj][0] = -sc*mxGetPr(ux)[jj] - cs*mxGetPi(ux)[jj] + 
                   cc*mxGetPr(uy)[jj] - ss*mxGetPi(uy)[jj];
      u0b[jj][1] = -sc*mxGetPi(ux)[jj] + cs*mxGetPr(ux)[jj] + 
                   cc*mxGetPi(uy)[jj] + ss*mxGetPr(uy)[jj];
    }
  else if (mxIsComplex(ux))
    for(jj = 0; jj < nt; jj++) {
      u0a[jj][0] = cc*mxGetPr(ux)[jj] + ss* mxGetPi(ux)[jj] + 
                   sc*mxGetPr(uy)[jj];
      u0a[jj][1] = cc*mxGetPi(ux)[jj] - ss*mxGetPr(ux)[jj] + 
                   cs*mxGetPr(uy)[jj];
      u0b[jj][0] = -sc*mxGetPr(ux)[jj] - cs*mxGetPi(ux)[jj] + 
                   cc*mxGetPr(uy)[jj];
      u0b[jj][1] = -sc*mxGetPi(ux)[jj] + cs*mxGetPr(ux)[jj] + 
                   ss*mxGetPr(uy)[jj];
    }
  else if (mxIsComplex(uy))
    for(jj = 0; jj < nt; jj++) {
      u0a[jj][0] = cc*mxGetPr(ux)[jj] +  
                   sc*mxGetPr(uy)[jj] - cs*mxGetPi(uy)[jj];
      u0a[jj][1] = - ss*mxGetPr(ux)[jj] + 
                   sc*mxGetPi(uy)[jj] + cs*mxGetPr(uy)[jj];
      u0b[jj][0] = -sc*mxGetPr(ux)[jj] + 
                   cc*mxGetPr(uy)[jj] - ss*mxGetPi(uy)[jj];
      u0b[jj][1] = cs*mxGetPr(ux)[jj] + 
                   cc*mxGetPi(uy)[jj] + ss*mxGetPr(uy)[jj];
    }
  else 
    for(jj = 0; jj < nt; jj++) {
      u0a[jj][0] = cc*mxGetPr(ux)[jj] +  
                   sc*mxGetPr(uy)[jj];
      u0a[jj][1] = - ss*mxGetPr(ux)[jj] + 
                   cs*mxGetPr(uy)[jj];
      u0b[jj][0] = -sc*mxGetPr(ux)[jj] + 
                   cc*mxGetPr(uy)[jj];
      u0b[jj][1] = cs*mxGetPr(ux)[jj] + 
                   ss*mxGetPr(uy)[jj];
    }
}


/* Compute vector of angular frequency components
 * MATLAB equivalent:  w = wspace(tv); */
void compute_w(REAL* w,REAL dt,int nt)
{
  int jj;
  for (jj = 0; jj <= (nt-1)/2; jj++) {
    w[jj] = 2*pi*jj/(dt*nt);
  }
  for (; jj < nt; jj++) {
    w[jj] = 2*pi*jj/(dt*nt) - 2*pi/dt;
  }
}


/* Compute ha & hb
 * ha = exp[(-alphaa(w)/2 - j*betaa(w))*dz/2])
 * hb = exp[(-alphab(w)/2 - j*betab(w))*dz/2]) 
 *
 * MATLAB Equivalent of ha (similar for hb):
 *   if (length(alphaa) == nt)   % If the user manually specifies alpha(w)
 *     ha = -alphaa/2;
 *   else
 *     ha = 0;
 *     for ii = 0:length(alphaa)-1;
 *       ha = ha - alphaa(ii+1)*(w).^ii/factorial(ii);
 *     end
 *     ha = ha/2;
 *   end
 *
 *   if (length(betapa) == nt)   % If the user manually specifies beta(w)
 *     ha = ha - j*betapa;
 *   else
 *     for ii = 0:length(betapa)-1;
 *       ha = ha - j*betapa(ii+1)*(w).^ii/factorial(ii);
 *     end
 *   end
 *   ha = exp(ha.*dz/2); % ha = exp[(-alphaa/2 - j*betaa)*dz/2])
 */
void compute_hahb(COMPLEX* ha,COMPLEX* hb,const mxArray* mxAlphaa,
                  const mxArray* mxAlphab,const mxArray* mxBetaa,const mxArray* mxBetab,
                  REAL* w,REAL dz,int nt)
{
  int nalphaa,nalphab,nbetaa,nbetab;    /* # of elements */
  double *alphaa,*alphab,*betaa,*betab; /* taylor coefficients */
  REAL fii,wii,aa,ab,phasea,phaseb;     /* temporary variables */
  int jj,ii;                            /* counters */
  
  nalphaa = mxGetNumberOfElements(mxAlphaa);
  nalphab = mxGetNumberOfElements(mxAlphab);
  nbetaa = mxGetNumberOfElements(mxBetaa);
  nbetab = mxGetNumberOfElements(mxBetab);
  alphaa = mxGetPr(mxAlphaa);
  alphab = mxGetPr(mxAlphab);
  betaa = mxGetPr(mxBetaa);
  betab = mxGetPr(mxBetab);
  
  for (jj = 0; jj < nt; jj++) {
    if (nalphaa != nt)
	  for (ii = 0, aa = 0, fii = 1, wii = 1; 
		   ii < nalphaa; 
		   ii++, fii*=ii, wii*=w[jj]) 
		aa += wii*((REAL) alphaa[ii])/fii;
  	else
	  aa = (REAL)alphaa[jj];
    if (nalphab != nt)
	  for (ii = 0, ab = 0, fii = 1, wii = 1; 
		   ii < nalphab; 
		   ii++, fii*=ii, wii*=w[jj]) 
		ab += wii*((REAL) alphab[ii])/fii;
  	else
	  ab = (REAL)alphab[jj];
    if (nbetaa != nt) 	 
	  for (ii = 0, phasea = 0, fii = 1, wii = 1; 
		   ii < nbetaa; 
		   ii++, fii*=ii, wii*=w[jj]) 
		phasea += wii*((REAL)betaa[ii])/fii;
  	else 
	  phasea = (REAL)betaa[jj];
    if (nbetab != nt) 	 
	  for (ii = 0, phaseb = 0, fii = 1, wii = 1; 
		   ii < nbetab; 
		   ii++, fii*=ii, wii*=w[jj]) 
		phaseb += wii*((REAL)betab[ii])/fii;
  	else 
	  phaseb = (REAL)betab[jj];
    ha[jj][0] = +exp(-aa*dz/4)*cos(phasea*dz/2);
    ha[jj][1] = -exp(-aa*dz/4)*sin(phasea*dz/2);
    hb[jj][0] = +exp(-ab*dz/4)*cos(phaseb*dz/2);
    hb[jj][1] = -exp(-ab*dz/4)*sin(phaseb*dz/2);
  }
}


/* Compute H matrix = [ h11 h12 
 *                      h21 h22 ] for linear propagation 
 *
 * MATLAB Equivalent:
 *   h11 = ( (1+sin(2*chi))*ha + (1-sin(2*chi))*hb )/2;
 *   h12 = -j*exp(+j*2*psi)*cos(2*chi)*(ha-hb)/2;
 *   h21 = +j*exp(-j*2*psi)*cos(2*chi)*(ha-hb)/2;
 *   h22 = ( (1-sin(2*chi))*ha + (1+sin(2*chi))*hb )/2;
 */
void compute_H(COMPLEX* h11,COMPLEX* h12,COMPLEX* h21,COMPLEX* h22,
               COMPLEX* ha,COMPLEX* hb,REAL chi,REAL psi,int nt)
{
  int jj;
  REAL halfPsin,halfMsin,sincos,coscos;
  halfPsin = .5 + .5*sin(2*chi);
  halfMsin = .5 - .5*sin(2*chi);
  sincos = .5*sin(2*psi)*cos(2*chi);
  coscos = .5*cos(2*psi)*cos(2*chi);
  
  for(jj = 0; jj < nt; jj++)
  {
    h11[jj][0] = halfPsin*ha[jj][0] + halfMsin*hb[jj][0];
    h11[jj][1] = halfPsin*ha[jj][1] + halfMsin*hb[jj][1];
    h12[jj][0] = sincos*(ha[jj][0]-hb[jj][0])+ 
                 coscos*(ha[jj][1]-hb[jj][1]);
    h12[jj][1] = sincos*(ha[jj][1]-hb[jj][1])- 
                 coscos*(ha[jj][0]-hb[jj][0]);
    h21[jj][0] = sincos*(ha[jj][0]-hb[jj][0]) -
                 coscos*(ha[jj][1]-hb[jj][1]);
    h21[jj][1] = sincos*(ha[jj][1]-hb[jj][1]) +
                 coscos*(ha[jj][0]-hb[jj][0]);
    h22[jj][0] = halfMsin*ha[jj][0] + halfPsin*hb[jj][0];
    h22[jj][1] = halfMsin*ha[jj][1] + halfPsin*hb[jj][1];
  }
}


/* Computes elliptical linear progation according to 
 * the matrix multiplication of:
 *   [ Ua(Z) ] = [ ha  0  ] * [ Ua(0) ]
 *   [ Ub(Z) ]   [ 0   hb ]   [ Ub(0) ] 
 *
 * MATLAB Equivalent:
 *   uZa = ha .* u0a;
 *   uZb = hb .* u0b;
 */
void prop_linear_ellipt(COMPLEX* uZa, COMPLEX* uZb, COMPLEX* ha,
                        COMPLEX* hb,COMPLEX* u0a,COMPLEX* u0b,int nt)
{
  int jj;

  for (jj = 0; jj < nt; jj++) {
    uZa[jj][0] = ha[jj][0]*u0a[jj][0] - ha[jj][1]*u0a[jj][1] ;
    uZa[jj][1] = ha[jj][0]*u0a[jj][1] + ha[jj][1]*u0a[jj][0] ;
    uZb[jj][0] = hb[jj][0]*u0b[jj][0] - hb[jj][1]*u0b[jj][1] ;
    uZb[jj][1] = hb[jj][0]*u0b[jj][1] + hb[jj][1]*u0b[jj][0] ;
  }
}


/* Computes the circular linear progation according to the 
 * matrix multiplication of:
 *   [ Ua(Z) ] = [ h11 h12 ] * [ Ua(0) ]
 *   [ Ub(Z) ] = [ h21 h22 ]   [ Ub(0) ] 
 *
 * MATLAB Equivalent:
 *   uZa = h11 .* u0a + h12 .* u0b;
 *   uZb = h21 .* u0a + h22 .* u0b;
 */
void prop_linear_circ(COMPLEX* uZa, COMPLEX* uZb, COMPLEX* h11,
                      COMPLEX* h12,COMPLEX* h21,COMPLEX* h22,COMPLEX* u0a,
                      COMPLEX* u0b,int nt)
{
  int jj;

  for (jj = 0; jj < nt; jj++) {
    uZa[jj][0] = h11[jj][0]*u0a[jj][0] + h12[jj][0]*u0b[jj][0] -
                 h11[jj][1]*u0a[jj][1] - h12[jj][1]*u0b[jj][1];
    uZa[jj][1] = h11[jj][0]*u0a[jj][1] + h12[jj][0]*u0b[jj][1] +
                 h11[jj][1]*u0a[jj][0] + h12[jj][1]*u0b[jj][0];
    uZb[jj][0] = h21[jj][0]*u0a[jj][0] + h22[jj][0]*u0b[jj][0] -
                 h21[jj][1]*u0a[jj][1] - h22[jj][1]*u0b[jj][1];
    uZb[jj][1] = h21[jj][0]*u0a[jj][1] + h22[jj][0]*u0b[jj][1] +
                 h21[jj][1]*u0a[jj][0] + h22[jj][1]*u0b[jj][0];
  }
}


/* Computes nonlinear propagation according to the following equations:
 *
 * Elliptical Equivalent:
 * dua/dz = (-j*gamma/3)*[(2+cos(2X)^2*|ua|^2 + (2+2sin(2X)^2)*|ub|^2] * ua
 * dub/dz = (-j*gamma/3)*[(2+cos(2X)^2*|ub|^2 + (2+2sin(2X)^2)*|ua|^2] * ub
 *
 * Circular Equivalent:
 * dua/dz = (-j*2*gamma/3)*(|ua|^2 + 2*|ub|^2)*ua
 * dub/dz = (-j*2*gamma/3)*(|ub|^2 + 2*|ua|^2)*ub
 */
void nonlinear_propagate(COMPLEX* uva,COMPLEX* uvb,COMPLEX* uahalf,
                    COMPLEX* ubhalf,COMPLEX* u0a,COMPLEX* u0b,
                    COMPLEX* u1a,COMPLEX* u1b,REAL gamma,REAL dz,
                    REAL chi, int nt)
{
  int jj;
  REAL coef,twoPcos,twoPsin;
  coef = (REAL) ((1.0/3.0)*gamma*dz);
  twoPcos = (2 + cos(2*chi)*cos(2*chi)) / 2;
  twoPsin = (2 + 2*sin(2*chi)*sin(2*chi)) / 2;
    
  for(jj = 0; jj < nt; jj++) {
    uva[jj][0] = uahalf[jj][0]*cos(coef*(
                   twoPcos*(abs2(&u0a[jj])+abs2(&u1a[jj])) +
                   twoPsin*(abs2(&u0b[jj])+abs2(&u1b[jj])) )) 
               + uahalf[jj][1]*sin(coef*(
                   twoPcos*(abs2(&u0a[jj])+abs2(&u1a[jj])) +
                   twoPsin*(abs2(&u0b[jj])+abs2(&u1b[jj])) ));
    uva[jj][1] = uahalf[jj][1]*cos(coef*(
                   twoPcos*(abs2(&u0a[jj])+abs2(&u1a[jj])) +
                   twoPsin*(abs2(&u0b[jj])+abs2(&u1b[jj])) )) 
               - uahalf[jj][0]*sin(coef*(
                   twoPcos*(abs2(&u0a[jj])+abs2(&u1a[jj])) +
                   twoPsin*(abs2(&u0b[jj])+abs2(&u1b[jj])) ));
    uvb[jj][0] = ubhalf[jj][0]*cos(coef*(
                   twoPcos*(abs2(&u0b[jj])+abs2(&u1b[jj])) +
                   twoPsin*(abs2(&u0a[jj])+abs2(&u1a[jj])) )) 
               + ubhalf[jj][1]*sin(coef*(
                   twoPcos*(abs2(&u0b[jj])+abs2(&u1b[jj])) +
                   twoPsin*(abs2(&u0a[jj])+abs2(&u1a[jj])) ));
    uvb[jj][1] = ubhalf[jj][1]*cos(coef*(
                   twoPcos*(abs2(&u0b[jj])+abs2(&u1b[jj])) +
                   twoPsin*(abs2(&u0a[jj])+abs2(&u1a[jj])) )) 
               - ubhalf[jj][0]*sin(coef*(
                   twoPcos*(abs2(&u0b[jj])+abs2(&u1b[jj])) +
                   twoPsin*(abs2(&u0a[jj])+abs2(&u1a[jj])) ));
  }
}


/* Returns non-zero if uva & uvb have converged towards u1a & u1b with
 * a tolerance less than tol 
 *
 * MATLAB equivalent:
 *   ( sqrt(norm(uva-u1a,2).^2+norm(uvb-u1b,2).^2) / ...
 *      sqrt(norm(u1a,2).^2+norm(u1b,2).^2) ) < tol 
 */
int is_converged(COMPLEX* uva,COMPLEX* u1a,COMPLEX* uvb,COMPLEX* u1b,
                 REAL tol,int nt) 
{ 
  int jj;
  REAL num,denom;
  for(jj = 0, num = 0, denom = 0; jj < nt; jj++) {
    num += (uva[jj][0]/nt-u1a[jj][0])*(uva[jj][0]/nt-u1a[jj][0]) +  
           (uva[jj][1]/nt-u1a[jj][1])*(uva[jj][1]/nt-u1a[jj][1]) +
           (uvb[jj][0]/nt-u1b[jj][0])*(uvb[jj][0]/nt-u1b[jj][0]) +  
           (uvb[jj][1]/nt-u1b[jj][1])*(uvb[jj][1]/nt-u1b[jj][1]);
    denom += abs2(&u1a[jj]) + abs2(&u1b[jj]);
  }
  return ( sqrt(num)/sqrt(denom) < tol);
}


/* Rotates back to input coordinate system, where u1x & u1y are the 
 * outputs and u1a and u1b are the inputs 
 *
 * Elliptical equivalent:
 *   u1x = ( cos(psi)*cos(chi) + j*sin(psi)*sin(chi))*u1a + ...
 *         (-sin(psi)*cos(chi) - j*cos(psi)*sin(chi))*u1b;
 *   u1y = ( sin(psi)*cos(chi) - j*cos(psi)*sin(chi))*u1a + ...
 *         ( cos(psi)*cos(chi) - j*sin(psi)*sin(chi))*u1b;
 * 
 * Circular MATLAB equivalent (when chi = pi/4 and psi = 0):
 *   u1x = (1/sqrt(2)).*(u1a-j*u1b) ;
 *   u1y = (1/sqrt(2)).*(-j*u1a+u1b) ;
 */
void inv_rotate_coord(mxArray* u1x, mxArray* u1y,COMPLEX* u1a,COMPLEX* u1b,
                      REAL chi, REAL psi, int nt) 
{ 
  REAL cc = cos(psi)*cos(chi);
  REAL ss = sin(psi)*sin(chi);
  REAL sc = sin(psi)*cos(chi);
  REAL cs = cos(psi)*sin(chi);
  int jj;
  for(jj = 0; jj < nt; jj++) {
    mxGetPr(u1x)[jj] = cc*u1a[jj][0] - ss*u1a[jj][1] -
                       sc*u1b[jj][0] + cs*u1b[jj][1];
    mxGetPi(u1x)[jj] = cc*u1a[jj][1] + ss*u1a[jj][0] -
                       sc*u1b[jj][1] - cs*u1b[jj][0];
    mxGetPr(u1y)[jj] = sc*u1a[jj][0] + cs*u1a[jj][1] +
                       cc*u1b[jj][0] + ss*u1b[jj][1];
    mxGetPi(u1y)[jj] = sc*u1a[jj][1] - cs*u1a[jj][0] +
                       cc*u1b[jj][1] - ss*u1b[jj][0];
  }
}


/* This is the gateway function between MATLAB and SSPROPVC.  It
 * serves as the main(). */
void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{ 
  COMPLEX *u0a, *u0b, *uafft, *ubfft, *uahalf, *ubhalf,
          *uva, *uvb, *u1a, *u1b;
  
  COMPLEX *ha, *hb;  /* exp{ (-Alpha(w)/2-jBeta(w)) z} */
  COMPLEX *h11, *h12,/* linear propgation coefficients */
          *h21, *h22;
    
  REAL dt;           /* time step */
  REAL dz;           /* propagation stepsize */
  int nz;            /* number of z steps to take */
  REAL gamma;        /* nonlinearity coefficient */
  REAL chi = 0.0;    /* degree of ellipticity  */
  REAL psi = 0.0;    /* angular orientation to x-axis  */
  int maxiter = 4;   /* max number of iterations */
  REAL tol = 1e-5;   /* convergence tolerance */

  int nt;            /* number of fft points */
  
  REAL* w;           /* vector of angular frequencies */

  PLAN p1a,p1b,ip1a,ip1b;   /* fft plans for 1st linear half */
  PLAN p2a,p2b,ip2a,ip2b;   /* fft plans for 2nd linear half */
  
  int converged;            /* holds the return of is_converged */
  char methodstr[11];       /* method name: 'circular or 'elliptical' */
  int elliptical = 1;       /* if elliptical method, then != 0 */

  char argstr[100];	 /* string argument */
  
  int iz,ii,jj;      /* loop counters */
  
  if (nrhs == 1) {
	if (mxGetString(prhs[0],argstr,100)) 
	  mexErrMsgTxt("Unrecognized option.");
	
	if (!strcmp(argstr,"-savewisdom")) {
	  sspropvc_save_wisdom();
	}
	else if (!strcmp(argstr,"-forgetwisdom")) {
	  FORGET_WISDOM();
	}
	else if (!strcmp(argstr,"-loadwisdom")) {
	  sspropvc_load_wisdom();
	}
	else if (!strcmp(argstr,"-patient")) {
	  method = FFTW_PATIENT;
	}
	else if (!strcmp(argstr,"-exhaustive")) {
	  method = FFTW_EXHAUSTIVE;
	}
	else if (!strcmp(argstr,"-measure")) {
	  method = FFTW_MEASURE;
	}
	else if (!strcmp(argstr,"-estimate")) {
	  method = FFTW_ESTIMATE;
	}
	else
	  mexErrMsgTxt("Unrecognized option.");
	return;
  }
  
  if (nrhs < 10) 
    mexErrMsgTxt("Not enough input arguments provided.");
  if (nlhs > 2)
    mexErrMsgTxt("Too many output arguments.");
  
  if (firstcall) {  /* attempt to load wisdom file on first call */
	sspropvc_load_wisdom();
    firstcall = 0;
  }

  /* parse input arguments */
  dt = (REAL) mxGetScalar(prhs[2]);
  dz = (REAL) mxGetScalar(prhs[3]);
  nz = round(mxGetScalar(prhs[4]));
  gamma = (REAL) mxGetScalar(prhs[9]);

  if (nrhs > 10) { /* default is chi = psi = 0.0 */
    psi = (REAL) mxGetScalar(prhs[10]); 
	if (mxGetNumberOfElements(prhs[10]) > 1)
	  chi = (REAL) (mxGetPr(prhs[10])[1]); 
  } 
 
  if (nrhs > 11) { /* default method is elliptical */
    if (mxGetString(prhs[11],methodstr,11)) /* fail */
      mexErrMsgTxt("incorrect method: elliptical or ciruclar only");
    else { /* success */
      if (!strcmp(methodstr,"circular"))
        elliptical = 0;
      else if(!strcmp(methodstr,"elliptical"))
        elliptical = 1;
      else
         mexErrMsgTxt("incorrect method: elliptical or ciruclar only");
    }
  }
    
  if (nrhs > 12) /* default = 4 */
	maxiter = round(mxGetScalar(prhs[12]));
  
  if (nrhs > 13) /* default = 1e-5 */
	tol = (REAL) mxGetScalar(prhs[13]);

  nt = mxGetNumberOfElements(prhs[0]);  /* # of points in vectors */
  
  /* allocate memory */
  u0a = (COMPLEX*) mxMalloc(sizeof(COMPLEX)*nt);
  u0b = (COMPLEX*) mxMalloc(sizeof(COMPLEX)*nt);
  uafft = (COMPLEX*) mxMalloc(sizeof(COMPLEX)*nt);
  ubfft = (COMPLEX*) mxMalloc(sizeof(COMPLEX)*nt);
  uahalf = (COMPLEX*) mxMalloc(sizeof(COMPLEX)*nt);
  ubhalf = (COMPLEX*) mxMalloc(sizeof(COMPLEX)*nt);
  uva = (COMPLEX*) mxMalloc(sizeof(COMPLEX)*nt);
  uvb = (COMPLEX*) mxMalloc(sizeof(COMPLEX)*nt);
  u1a = (COMPLEX*) mxMalloc(sizeof(COMPLEX)*nt);
  u1b = (COMPLEX*) mxMalloc(sizeof(COMPLEX)*nt);
  ha = (COMPLEX*) mxMalloc(sizeof(COMPLEX)*nt);
  hb = (COMPLEX*) mxMalloc(sizeof(COMPLEX)*nt);
  h11 = (COMPLEX*) mxMalloc(sizeof(COMPLEX)*nt);
  h12 = (COMPLEX*) mxMalloc(sizeof(COMPLEX)*nt);
  h21 = (COMPLEX*) mxMalloc(sizeof(COMPLEX)*nt);
  h22 = (COMPLEX*) mxMalloc(sizeof(COMPLEX)*nt);
  w = (REAL*)mxMalloc(sizeof(REAL)*nt);
  plhs[0] = mxCreateDoubleMatrix(nt,1,mxCOMPLEX);
  plhs[1] = mxCreateDoubleMatrix(nt,1,mxCOMPLEX);
  
  /* fftw3 plans */
  p1a = MAKE_PLAN(nt, u0a, uafft, FFTW_FORWARD, method);
  p1b = MAKE_PLAN(nt, u0b, ubfft, FFTW_FORWARD, method);
  ip1a = MAKE_PLAN(nt, uahalf, uahalf, FFTW_BACKWARD, method);
  ip1b = MAKE_PLAN(nt, ubhalf, ubhalf, FFTW_BACKWARD, method);
  p2a = MAKE_PLAN(nt, uva, uva, FFTW_FORWARD, method);
  p2b = MAKE_PLAN(nt, uvb, uvb, FFTW_FORWARD, method);
  ip2a = MAKE_PLAN(nt, uafft, uva, FFTW_BACKWARD, method);
  ip2b = MAKE_PLAN(nt, ubfft, uvb, FFTW_BACKWARD, method);

  allocated = 1;
  
  /* Compute vector of angular frequency components
   * MATLAB equivalent:  w = wspace(tv); */
  compute_w(w,dt,nt);
  
  /* Compute ha & hb vectors
   * ha = exp[(-alphaa(w)/2 - j*betaa(w))*dz/2])
   * hb = exp[(-alphab(w)/2 - j*betab(w))*dz/2]) 
   * prhs[5]=alphaa  prhs[6]=alphab  prhs[7]=betaa  prhs[8]=betab */
  compute_hahb(ha,hb,prhs[5],prhs[6],prhs[7],prhs[8],w,dz,nt);
  
  mexPrintf("Performing split-step iterations ... ");
  
  if (elliptical) { /* Elliptical Method */
    
    /* Rotate to eignestates of fiber 
     *   u0a = ( cos(psi)*cos(chi) - j*sin(psi)*sin(chi))*u0x + ...
     *         ( sin(psi)*cos(chi) + j*cos(psi)*sin(chi))*u0y;
     *   u0b = (-sin(psi)*cos(chi) + j*cos(psi)*sin(chi))*u0x + ...
     *         ( cos(psi)*cos(chi) + j*sin(psi)*sin(chi))*u0y;
     */
    rotate_coord(u0a,u0b,prhs[0],prhs[1],chi,psi,nt);
      
    cscale(u1a,u0a,u1b,u0b,1.0,nt); /* u1a=u0a  u1b=u0b */
    
    EXECUTE(p1a);  /* uafft = fft(u0a) */
    EXECUTE(p1b);  /* ubfft = fft(u0b) */
    
    for(iz=1; iz <= nz; iz++)
    {
      /* Linear propagation (1st half):
       * uahalf = ha .* uafft
       * ubhalf = hb .* ubfft */
      prop_linear_ellipt(uahalf,ubhalf,ha,hb,uafft,ubfft,nt);
      
      EXECUTE(ip1a);  /* uahalf = ifft(uahalf) */
      EXECUTE(ip1b);  /* ubhalf = ifft(ubhalf) */
      
      /* uahalf=uahalf/nt  ubhalf=ubhalf/nt */
      cscale(uahalf,uahalf,ubhalf,ubhalf,1.0/nt,nt);
  
      ii = 0;
      do
      {
        /* Calculate nonlinear section: output=uva,uvb */
        nonlinear_propagate(uva,uvb,uahalf,ubhalf,u0a,u0b,u1a,u1b,
                            gamma,dz,chi,nt);
        
      
        EXECUTE(p2a);  /* uva = fft(uva) */
        EXECUTE(p2b);  /* uvb = fft(uvb) */
      
        /* Linear propagation (2nd half):
         * uafft = ha .* uva
         * ubfft = hb .* uvb */
         prop_linear_ellipt(uafft,ubfft,ha,hb,uva,uvb,nt);
     
        EXECUTE(ip2a);  /* uva = ifft(uafft) */
        EXECUTE(ip2b);  /* uvb = ifft(ubfft) */
        
        /* Check if uva & u1a  and  uvb & u1b converged 
         * converged = ( ( sqrt(norm(uva-u1a,2).^2+norm(uvb-u1b,2).^2) /...
         *                 sqrt(norm(u1a,2).^2+norm(u1b,2).^2) ) < tol )
         */
        converged = is_converged(uva,u1a,uvb,u1b,tol,nt);
      
        /* u1a=uva/nt  u1b=uvb/nt */
        cscale(u1a,uva,u1b,uvb,1.0/nt,nt);
      
        ii++;
      } while(!converged && ii < maxiter);  /* end convergence loop */
    
      if(ii == maxiter)
        mexPrintf("Warning: Failed to converge to %f in %d iterations\n",
                  tol,maxiter);
    
      /* u0a=u1a  u0b=u1b */
      cscale(u0a,u1a,u0b,u1b,1.0,nt);

    } /* end step loop */
    
    /* Rotate back to original x-y basis
     *  u1x = ( cos(psi)*cos(chi) + j*sin(psi)*sin(chi))*u1a + ...
     *        (-sin(psi)*cos(chi) - j*cos(psi)*sin(chi))*u1b;
     *  u1y = ( sin(psi)*cos(chi) - j*cos(psi)*sin(chi))*u1a + ...
     *        ( cos(psi)*cos(chi) - j*sin(psi)*sin(chi))*u1b;
     */
    inv_rotate_coord(plhs[0],plhs[1],u1a,u1b,chi,psi,nt);
    
  } 
  else {  /* Circular method */ 
    
    /* Compute H matrix = [ h11 h12 
     *                      h21 h22 ] for linear propagation
     *   h11 = ( (1+sin(2*chi))*ha + (1-sin(2*chi))*hb )/2;
     *   h12 = -j*exp(+j*2*psi)*cos(2*chi)*(ha-hb)/2;
     *   h21 = +j*exp(-j*2*psi)*cos(2*chi)*(ha-hb)/2;
     *   h22 = ( (1-sin(2*chi))*ha + (1+sin(2*chi))*hb )/2;
     */
    compute_H(h11,h12,h21,h22,ha,hb,chi,psi,nt);
      
    /* Rotate to circular coordinate system 
     *   u0a = (1/sqrt(2)).*(u0x + j*u0y);
     *   u0b = (1/sqrt(2)).*(j*u0x + u0y); */
    rotate_coord(u0a,u0b,prhs[0],prhs[1],pi/4,0,nt);
      
    cscale(u1a,u0a,u1b,u0b,1.0,nt); /* u1a=u0a  u1b=u0b */
    
    EXECUTE(p1a);  /* uafft = fft(u0a) */
    EXECUTE(p1b);  /* ubfft = fft(u0b) */
      
    for(iz=1; iz <= nz; iz++)
    {
      /* Linear propagation (1st half):
       * uahalf = h11 .* uafft + h12 .* ubfft
       * ubhalf = h21 .* uafft + h22 .* ubfft */
      prop_linear_circ(uahalf,ubhalf,h11,h12,h21,h22,uafft,ubfft,nt);
      
      EXECUTE(ip1a);  /* uahalf = ifft(uahalf) */
      EXECUTE(ip1b);  /* ubhalf = ifft(ubhalf) */
      
      /* uahalf=uahalf/nt  ubhalf=ubhalf/nt */
      cscale(uahalf,uahalf,ubhalf,ubhalf,1.0/nt,nt);
  
      ii = 0;
      do
      {
        /* Calculate nonlinear section: output=uva,uvb */
         nonlinear_propagate(uva,uvb,uahalf,ubhalf,u0a,u0b,u1a,u1b,
                             gamma,dz,pi/4,nt);
      
        EXECUTE(p2a);  /* uva = fft(uva) */
        EXECUTE(p2b);  /* uvb = fft(uvb) */
      
        /* Linear propagation (2nd half):
         * uafft = h11 .* uva + h12 .* uvb
         * ubfft = h21 .* uva + h22 .* uvb */
        prop_linear_circ(uafft,ubfft,h11,h12,h21,h22,uva,uvb,nt);
     
        EXECUTE(ip2a);  /* uva = ifft(uafft) */
        EXECUTE(ip2b);  /* uvb = ifft(ubfft) */
      
        /* Check if uva & u1a  and  uvb & u1b converged 
         *   ( sqrt(norm(uva-u1a,2).^2+norm(uvb-u1b,2).^2) /...
         *     sqrt(norm(u1a,2).^2+norm(u1b,2).^2) ) < tol
         */
        converged = is_converged(uva,u1a,uvb,u1b,tol,nt);
      
        /* u1a=uva/nt  u1b=uvb/nt */
        cscale(u1a,uva,u1b,uvb,1.0/nt,nt);
      
        ii++;
      } while(!converged && ii < maxiter);  /* end convergence loop */
    
      if(ii == maxiter)
        mexPrintf("Warning: Failed to converge to %f in %d iterations\n",
                  tol,maxiter);
    
      /* u0a=u1a  u0b=u1b */
      cscale(u0a,u1a,u0b,u1b,1.0,nt);

    } /* end step loop */
    
    /* Rotate back to orignal x-y basis
     *   u1x = (1/sqrt(2)).*(u1a-j*u1b) ;
     *   u1y = (1/sqrt(2)).*(-j*u1a+u1b) ; */
    inv_rotate_coord(plhs[0],plhs[1],u1a,u1b,pi/4,0,nt);
    
  } /* end circular method */      
  

  mexPrintf("done.\n");

  if (allocated) {
    /* destroy fftw3 plans */
    DESTROY_PLAN(p1a);
    DESTROY_PLAN(p1b);
    DESTROY_PLAN(ip1a);
    DESTROY_PLAN(ip1b);
    DESTROY_PLAN(p2a);
    DESTROY_PLAN(p2b);
    DESTROY_PLAN(ip2a);
    DESTROY_PLAN(ip2b);

    /* de-allocate memory */
    mxFree(u0a);
    mxFree(u0b);
    mxFree(uafft);
    mxFree(ubfft);
    mxFree(uahalf);
    mxFree(ubhalf);
    mxFree(uva);
    mxFree(uvb);
    mxFree(u1a);
    mxFree(u1b);
    mxFree(ha);
    mxFree(hb);
    mxFree(h11);
    mxFree(h12);
    mxFree(h21);
    mxFree(h22);
    mxFree(w);
    
    allocated = 0;
  }
} /* end mexFunction */
