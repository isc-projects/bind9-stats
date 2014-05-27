#!/bin/sh

mkdir -p OUTPUT
perl t03.pl | tee OUTPUT/t03-reference-output.txt | diff - t03-reference-output.txt
