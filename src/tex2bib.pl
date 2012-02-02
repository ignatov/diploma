#! /usr/bin/perl 

$Script = 'tex2bib'; 
$Version=0.97;  # 22 Feb 2006 10:50:35
$Author='Michael Friendly (friendly@yorku.ca)';

# Copyright (c) 1997 Michael Friendly
#
# License:
#  This is free software subject to copyright, released according to the
#  BSD style license.  It may be freely used, modified and distributed.
#  See: http://www.ctan.org/tex-archive/help/Catalogue/licenses.bsd.html
#  for details and further information.

# tex2bib
#   Input a TeX document containing \bibitems, translate these
#   to BibTeX format
#
# Usage:
#		tex2bib [-k][-i infile] [-o outfile]
#		-k:  regenerate keys
#		if infile not given, reads from stdin
#		if outfile not given, prints to stdout

# The entire tex document is scanned for \bibitems, ending when
# the string '\end{thebibliography}' is read.

# Assumes that bibitems are formatted as follows:
#  -- {key}author(s), (date) at the beginning
#  -- titles of books or names of journals: {\em title}
#  -- article titles: 	after date, `` '' quotes optional
#  -- volume, pages: 	{\it vol}, nnn-nnn.
#  -- publisher/address:    address:publisher
#
#  All text in the bibitem which cannot be parsed is included
#  in a note = { } field
#
# Changes
#  0.96 1998/06/22  Allow \bibitem keys to contain [\w:-]
#  0.97 2006/02/21  Added BSD license
#################################################################
# Examples of a book, article, inproceedings:

#\bibitem{Bertin83}Bertin, J. (1983),
#        {\em Semiology of Graphics} (trans. W. Berg).  Madison, WI:
#        University of Wisconsin Press.
#
#\bibitem{Bickel75}Bickel, P. J., Hammel, J. W. and O'Connell, J. W.
#        (1975).
#        Sex bias in graduate admissions: data from Berkeley.  {\em
#        Science}, {\it 187}, 398-403.
#
#\bibitem{Farebrother87}Farebrother, R. W. (1987),
#        ``Mechanical representations of the ${L}_1$ and ${L}_2$ estimation
#        problems'', In Y. Dodge (ed.)  {\em Statistical data analysis
#        based on the L1 norm and related methods}, Amsterdam:
#        North-Holland., 455-464.


# These are output as:

#@Book{  Bertin:83,
#    author      = {J. Bertin},
#    year        = 1983,
#    title       = {Semiology of Graphics},
#    publisher   = {University of Wisconsin Press},
#    address     = {Madison, WI},
#    note        = {(trans. W. Berg).}
#}
#@Article{       Bickel:75,
#    author      = {Bickel, P. J. and Hammel, J. W. and O'Connell, J. W.},
#    year        = 1975,
#    title       = {Sex Bias in Graduate Admissions: Data from Berkeley},
#    journal     = {Science},
#    volume      = 187,
#    pages       = {398-403}
#}
#@InCollection{  Farebrother:87,
#    author      = {R. W. Farebrother},
#    year        = 1987,
#    title       = {Mechanical Representations of the ${L}_1$ and ${L}_2$ Estimation Problems},
#    booktitle   = {Statistical Data Analysis Based on the L1 Norm and Related Methods},
#    editor      = {Y. Dodge},
#    publisher   = {North-Holland},
#    address     = {Amsterdam},
#    pages       = {455-464}

# Text in a bibitem is removed from the bibitem as it is assigned to
# bibtex fields.  Any text remaining is assigned to a note={  } field
# at the end.  Since the parsing is heuristic, some manual fixup work
# can be expected at the end.

#################################################################

require 'getopt.pl' ;

    Getopt("oikdrt:");             # ARGV now contains [inputfile] and
                                #   $opt_o, $opt_i might be set.
	
	$default_type = $opt_t || 'Article';
	
    open(STDIN, "<$opt_i") or die "-i $opt_i: can't open.\n" if $opt_i ;
    open(STDOUT, ">$opt_o") or die "-o $opt_o: can't create.\n" if $opt_o ;

#######################  Process input files  ####################
$bibs=0;
while (<>)
{
	/^\s*\\end\{thebibliography/ && last;
	if (/\\bibitem\s*\{([\w\d:-]+)\}/) {
		$bibs++;
		$key = $1;
#		print STDERR "$bibs key: $key\n";
	}
	# skip if we're still reading tex text (no bibitems encountered)
	next unless $bibs;
	chomp;
	s/^\s*/ /;
	$lines .= $_;
}

# All lines containing \bibitems have been read into the $lines string.
# Now, split into separate items

@items = split(/\\bibitem\s*/, $lines);
print STDERR "items has ", scalar(@items), " items\n";

@months = qw(january february march april may jun july august september
	october november december);
$month_pat = join('|', @months);

foreach (@months) {
	$month_abbrv{$_} = substr($_, 0,3);
}
	
$ordinal = 'first|second|third|fourth|1st\.?|2nd\.?|3rd\.?|4th\.?';

# title words to ignore for casing;
foreach ( qw(a about an and by for from in of on the to von with) ) {
	$ignore_case{$_} = 1;
}

$outitems =0;
%keys_seen = {};

foreach $i (0..$#items) {
	undef $title;
	undef $pages;
	undef $journal;
	undef $volume;
	undef $number;
	undef $booktitle;
	undef $editor;
	undef $edition;
	undef $month;
	undef $publisher;
	undef $address;
	undef $chapter;
	undef $rest;
	
	print "$items[$i]\n" if $opt_d;
	# assume each entry starts with
	#	{key}Author, F.I. etc (date[a-z]?)
#	$items[$i] =~ /^\{([^}]+)\}([^\(]*)\((\d{4})[a-z]?\)[,.]?\s*/;
#	($key, $authors, $date) = ($1, $2, $3);
	$items[$i] =~ /^\{([^}]+)\}\s*/;
	$key = $1;
#	print  "key: $key\n";
	$rest = $';
		
	$rest =~ /\((\d{4})[a-z]?\)[,.]?\s*/ &&
		do {
			$authors = $`;
			$date = $1;
			$rest = $';
		};

	unless (defined($key)) {
		print STDERR "Skipping: $authors, $date in \n$items[$i]\n";
		next;
	}
		

	$rest =~ s/^[.,]?\s+//;
	$rest =~ s/\s+$//;

#	print "key: $key\n";
#	$key =~ m/(['A-Za-z]+)([^:]*)/ &&
#		do { $key = "$1:$2"; };
#	print "key: $key\n";
			
	&parse_authors;

	$orig_key = $key;
	$key = &generate_key if $opt_k or $keys_seen{$key};
	
	# if the $key has already been seen, make a new, unique one
	if ($keys_seen{$key}) {
		foreach $suffix (('b'..'z')) {
			$try = $key . $suffix;
#			print STDERR "Seen $key ... trying $try\n";
			unless ($keys_seen{$try}) {$key = $try; last; };
		}
		print STDERR "New unique key generated: $key (was $orig_key)\n"
			unless $key eq $orig_key;
	}
	$keys_seen{$key}++;
	
	# assume it's an article at first
	$type = '@' . $default_type;

	if ($rest =~ /^\{\\em\s+/) {
	#tech report or book
		$type = '@Book';
		$rest =~ m/^\{\\em\s+(['\w ,?:]+)\}[., ]*/;
		$title = $1;
		$rest = $';
		&parse_edition;
		&parse_publish;

		$rest =~ m/\sreport(s?)[,]?\s*/i &&
			do {
				$type ='@TechReport';
				$rest = $` . $';
				&parse_report_number;
			};
	}

	else {
		#does it begin with quoted title?
		if ($rest =~ /^``/){
			$rest =~ m/^``([^`]+)''[., ]*/;
			$title = $1;
			$rest = $';
		}
		else {
			$rest =~ m#^(['\{\}\w\d,\(\)\\ :\?/-]+)[. ]*#;
			$title = $1;
			$rest = $';
		}
		$rest =~ s/^[,\s]+//;
		
		if ($rest =~ /^\{\\em\s+/) {
			$rest =~ m/^\{\\em\s+([\w\\& ,'-?]+)\}[., ]*/;
			$journal = $1;
			$rest = $';
		}
		# parse {\it volume (number)}
		&parse_volume;
			
		$rest =~ m/,?\s*(\d{1,4}--?\d{1,4})[.,]?\s*/ && 
			do {
			$pages = $1;
			$rest = $`. $';
			$pages =~ s/(\d)-(\d)/$1--$2/;
			};

		$rest =~ m/\(($month_pat)\)/i &&
			do {
				($month = $1) =~ tr/A-Z/a-z/;
				$month = $month_abbrv{$month};
				$rest = $` . $';
			};
			
		$rest =~ m/(technical|tech\.)\s+report[,.]?/i &&
			do {
				$type ='@TechReport';
				$rest = $` . $';
				&parse_report_number;
			};
		
		$rest =~ m/^In\s+/i &&
			do {
				$rest = $';
				$type ='@InCollection';  # maybe, proceedings
				$rest =~ m/\{\\em\s+([\w ,':!?]+)\}[., ]*/ &&
					do {
					$booktitle = $1;
					$rest = $` . $';
					$type = '@InProceedings' if $booktitle =~ m/proceedings/i;
					};
				$rest =~ m/([\w., ]+)\s+\(eds?\.\)[,.]?\s*/i &&
					do {
					$editor = $1;
					$rest = $` . $';
					};
				$rest =~ m/Chapter\s+(\d+)[.,]?\s*/i &&
					do {
					$chapter = $1;
					$rest = $` . $';
					};
				
				&parse_edition;
				&parse_publish;
			};

		$rest =~ m/proceedings/i &&
			do {
				$type = '@InProceedings';
#	print "$items[$i]\n";
			};
	}

	$rest =~ s/^\s+//;
	$rest =~ s/$date([,]?)//;
	
	$title = &case_title($title);
	$booktitle = &case_title($booktitle) if $booktitle;
	
	print "$type\{$key";
	print ",\n    author\t= {$authors}";
	print ",\n    year\t= $date";
	print ",\n    title\t= {$title}" if $title;
	print ",\n    booktitle\t= {$booktitle}" if $booktitle;
	print ",\n    edition\t= {$edition}" if $edition;
	print ",\n    editor\t= {$editor}" if $editor;
	print ",\n    publisher\t= {$publisher}" if $publisher;
	print ",\n    address\t= {$address}" if $address;
	print ",\n    journal\t= {$journal}" if $journal;
	print ",\n    volume\t= $volume" if $volume;
	print ",\n    month\t= $month" if $month;
	print ",\n    number\t= $number" if $number;
	print ",\n    pages\t= {$pages}" if $pages;
	print ",\n    chapter\t= {$chapter}" if $chapter;
	print ",\n    note\t= {$rest}" if $rest;
	print "\n\}\n";
	$outitems++;	
}
print STDERR "$outitems items processed\n";
exit;

########################### subroutines #############################

# separate multiple authors with 'and'
sub parse_authors {
	# fix authors field
	$authors =~ s/\s+$//;
	$authors =~ s/\\&/and/;
	$authors =~ s/([A-Z])\.([A-Z])\./$1. $2./g;
	$authors =~ s/ ([A-Z])\.,\s+(?!Jr.)/ $1. and /g;
	$authors =~ s/ and and / and /;
#	$authors =~ s/Friendly, M./Friendly, Michael/;
	$authors =~ s/M. Friendly/Friendly, M./;
	local($commas) = ($authors =~ tr/,/,/);
	if ($opt_r && $commas == 1) {
		@auth = split(/, /, $authors);
		$authors = join(' ',reverse(@auth));
	}

}

# extract last names of authors into @auth array
sub split_authors {
	@auth = split(/ and /, $authors);
	@auth =~ grep(s/, .*$//g,@auth);          # strip trailing initials
	@auth =~ grep(s/^([A-Z]\.\s*)+//g,@auth);
#	@auth =~ grep(s/^[a-z ]+//,@auth);        # strip any name prefixes

	foreach  $i (0..$#auth) {
		@n = split(/ /, $auth[$i]);
		$auth[$i] = pop(@n);               # strip anything before lastname
		$auth[$i] =~ s/[^\w]//g;           # remove non-word chars 		
	}
		
#	print STDERR "Authors: $authors --> ", 
		join('|',@auth),"\n"    if scalar(@auth) > 1;
		
}

sub parse_volume {
	$rest =~ m/,?\s*\{\\it\s+([A-Za-z \d()]+)\s*\}[.,]?/ &&
		do {
		$volume = $1;
		$rest = $`. $';
		$volume =~ m/\(([ \w]+)\)/ &&
			do {
				$volume = $`;
				$number = $1;
			};
		$volume = "{$volume}" unless $volume =~ m/^\d*$/;
		$number = "\{$number\}" unless $number =~ m/^\d*$/;
		};
			
}

# find publisher and address in book/inproceedings items
#	assume the format is address:publisher
sub parse_publish {
	local($before, $after);
	$rest =~ m#:\s*([\w-\\/& ]+)[.]?# &&
		do {
			$publisher = $1;
			($before, $after) = ($`, $');
			$before =~ m/([\w, ]+)$/ &&
				do {
				$address = $1;
				$before = $`;
				$address =~ s/^\s+//;
				};
			$rest = $before . $after;
		};
}

sub parse_report_number {
	$rest =~ m/\s*(no\.|number)\s+(\d+)[,.]?\s*/i &&
		do {
		$number = $2;
		$rest = $` . $';
		}
}

sub parse_edition {
	$rest =~ m/\(?($ordinal).*(edition|ed\.)\)?\.?\s*/i &&
		do {
		$edition = $1;
		$rest = $` . $';
		}
}

# Initial-caps for all non-ignored words
sub case_title {
	local($t) = @_;
	local(@words) = split(/\s+/, $t);
	local($w) =0;
	local($colon);
	foreach (@words) {
		$w++;
		next if /^[A-Z]/;
		unless ($colon) {next if $ignore_case{$_}};		
		s/^([a-z])/\u$1/;
		$colon = tr/:/:/;
	}
	join(' ', @words);
}

sub generate_key {
	local($yr, $key);
	($yr = $date) =~ s/^1\d//;
	&split_authors;	
	if (scalar(@auth) < 3) {
		$key = join('', @auth, ':', $yr);
	}
	else {
		$key = join('', $auth[0], '-etal:', $yr);
	}
#	print STDERR "New key: $key (", join('|', @auth), ": $date)\n";
	$key;
}
