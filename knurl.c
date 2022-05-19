
/*********************************************************************************
 * Compute diameters that will work out to an integer number of the pitchs for
 * a knurl wheel.
 *
 * Thu May 19 08:37:47 EDT 2022
 * John D. Robertson <john@rrci.com>
 *
 * Compile like so:
 *      cc knurl.c -lm -o knurl
 */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>


/* Edit these to suit your purpose */
double KnurlPitch_mm= 2.,
       MinStockDia_in= .75,
       MaxStockDia_in= 1.;

#define IN2MM 25.4
#define MM2IN (1./IN2MM)
#define MAX_DIFF_IN .001
#define STEP_IN (MAX_DIFF_IN/2.)

/*===========================================================================*/
/*======================== main() ===========================================*/
/*===========================================================================*/
int
main(int argc, char **argv)
{
   /* Print input parameters */
   printf(
         "knurl wheel pitch= %.1lf mm, min stock diameter= %.3lf inch, max diameter= %.3lf inch\n"
         , KnurlPitch_mm
         , MinStockDia_in
         , MaxStockDia_in
         );

   for(double dia= MaxStockDia_in; dia >= MinStockDia_in; dia -= STEP_IN) {

      /* Compute circumfurence and associated knurl wheel pitch modulus */
      double circ= M_PI*dia,
             pitchMod= fmod(circ, KnurlPitch_mm * MM2IN);

      /* Check to see if the knurl wheel's pitch modulus is too big */
      if(pitchMod > MAX_DIFF_IN)
         continue;

      /* Print appropriate diameter for knurling */
      printf("dia= %.3lf inch\n", dia);
//      printf("dia= %.3lf inch, pitchMod= %lf inch\n", dia, pitchMod);
   }

   return EXIT_SUCCESS;
}

