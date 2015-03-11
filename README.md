ISC-BIND-Stats-Parser version 1.00
==================================

The set of routines in ISC-BIND-Stats provides the module 
	ISC::BIND::Stats

this is an XML::SAX parser for the bind 9.x (v2 and v3 in 9.10) stats 
interface.

The program tools/monthly_summary turns the stats file into a (monthly) 
CSV file containing the totals.

To install this module type the following:

   cd ISC-BIND-Stats
   perl Makefile.PL
   make
   make test
   make install

DEPENDENCIES

This module requires these other modules and libraries:

  XML::SAX

COPYRIGHT AND LICENCE

Put the correct copyright and licence information here.

Copyright (C) 2012 by Francisco Obispo
Copyright (C) 2015 by Michael Richardson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.


