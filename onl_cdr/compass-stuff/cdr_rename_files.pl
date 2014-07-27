#!/usr/bin/perl

while(<cdr12*.raw>) {
	next unless /^cdr(\d\d)-(\d{3,6})_(\d{3})\.raw/;
	rename $_ , "cdrpccoeb$1-$2.$3.raw";
}
