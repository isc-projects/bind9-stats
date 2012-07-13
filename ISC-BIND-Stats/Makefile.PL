#!/usr/bin/env perl
# Copyright (C) 2004-2011  Internet Systems Consortium, Inc. ("ISC")
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND ISC DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS.  IN NO EVENT SHALL ISC BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
# OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.

use inc::Module::Install;

requires 'common::sense'    => '3.3';
requires 'Time::HiRes'      => '1.9719';
requires 'Try::Tiny';
requires 'IO::Uncompress::Bunzip2';
requires 'HTTP::Date';
requires 'MongoDB';
requires 'Data::Dumper';
requires 'Getopt::Long';


install_script 'bind_stats_import';

all_from 'lib/ISC/BIND/Stats.pm';

# License

license 'bsd';

WriteAll;

