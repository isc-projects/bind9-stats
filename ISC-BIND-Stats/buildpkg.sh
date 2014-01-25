#!/bin/sh

if [ -d /usr/local/share/perl/5.12.4/ExtUtils ]; 
then
	echo Please uninstall non-debian version of MakeMaker.
	exit 1
fi

fakeroot debian/rules binary
