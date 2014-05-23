#!/bin/sh

mkdir -p OUTPUT
perl t02.pl | tee OUTPUT/t02-reference-output.txt | diff - t02-reference-output.txt
