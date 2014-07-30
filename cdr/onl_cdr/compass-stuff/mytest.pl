#!/usr/bin/perl

while(<cdr*.dat>) {
    next unless /^cdr(\d{5})-(\d+)\.dat/;
    print "$1 $2\n";
}
