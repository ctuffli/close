# $Id$

class String;

sub ASSERT($condition, *@message) {
	close::Dumper::ASSERT(close::Dumper::info(), $condition, @message);
}

sub BACKTRACE() {
	Q:PIR {{
		backtrace
	}};
}

sub DIE(*@msg) {
	close::Dumper::DIE(close::Dumper::info(), @msg);
}

sub DUMP(*@pos, *%what) {
	close::Dumper::DUMP(close::Dumper::info(), @pos, %what);
}

sub NOTE(*@parts) {
	close::Dumper::NOTE(close::Dumper::info(), @parts);
}

################################################################

our %Cclass_id;
%Cclass_id<ANY>			:= 65535;
%Cclass_id<NONE>			:= 0;
%Cclass_id<UPPERCASE>		:= 1;
%Cclass_id<LOWERCASE>	:= 2;
%Cclass_id<ALPHABETIC>	:= 4;
%Cclass_id<NUMERIC>		:= 8;
%Cclass_id<HEXADECIMAL>	:= 16;
%Cclass_id<WHITESPACE>	:= 32;
%Cclass_id<PRINTING>		:= 64;
%Cclass_id<GRAPHICAL>		:= 128;
%Cclass_id<BLANK>		:= 256;
%Cclass_id<CONTROL>		:= 512;
%Cclass_id<PUNCTUATION>	:= 1024;
%Cclass_id<ALPHANUMERIC>	:= 2048;
%Cclass_id<NEWLINE>		:= 4096;
%Cclass_id<WORD>		:= 8192;

=sub char_at($str, $index)

Returns the character at C<$index> in C<$str>  -- that is, char_at($str, $index)
is equivalent to doing C<$str[$index]>, except that doesn't work.

=cut

sub char_at($str, $index) {
	NOTE("index = ", $index, ", str = ", $str);
	
	my $result := Q:PIR {
		$P0 = find_lex '$str'
		$P1 = find_lex '$index'
		$S1 = $P0[$P1]
		%r = box $S1
	};
	
	NOTE("Result = '", $result, "'");
	return $result;
}

=sub display_width($str) {

Compute the display width of the C<$str>, assuming that tabs
are 8 characters wide, and all other chars are 1 character wide. Thus, a 
sequence like tab-space-space-tab will have a width of 16, since the two spaces
do not equate to a full tab stop.

Returns the computed width of C<$str>.

=cut

sub display_width($str) {
	my $width := 0;
	
	if $str {
		my $i := 0;
		my $len := length($str);
		
		while $i < $len {
			if char_at($str, $i) eq "\t" {
				$width := $width + 8 - ($width % 8);
			}
			else {
				$width++;
			}
			
			$i++;
		}
	}

	return $width;
}

=sub find_cclass($class_name, $str, [:offset(#),] [:count(#)])

Returns the index of the first character in C<$str> at or after C<:offset()> that
is a member of the character class C<$class_name>. If C<:count()> is 
specified, scanning ends after the C<:count()> characters have been scanned. 
By default, C<:offset(0)> and C<:count(length($str))> are used.

If no matching characters are found, returns the last index plus one.

=cut

sub find_cclass($class_name, $str, *%opts) {
	my $offset	:= 0 + %opts<offset>;
	my $count	:= %opts<count>;
	
	unless $count {
		$count := length($str) - $offset;
	}
	
	my $cclass := 0 + %Cclass_id{$class_name};
	
	NOTE("class = ", $class_name, "(", $cclass, "), offset = ", $offset, ", count = ", $count, ", str = ", $str);

	my $result := Q:PIR {
		.local int cclass, offset, count
		$P0 = find_lex '$cclass'
		cclass = $P0
		$P0 = find_lex '$offset'
		offset = $P0
		$P0 = find_lex '$count'
		count = $P0
		
		.local string str
		$P0 = find_lex '$str'
		str = $P0
	
		$I0 = find_cclass cclass, str, offset, count
		%r = box $I0
		
	};
	
	NOTE("Result = ", $result);
	return $result;
}

=sub find_not_cclass($class_name, $str, [:offset(#),] [:count(#)])

Behaves like L<#find_cclass> except that the search is for the first
character B<not> a member of C<$class_name>. Useful for skipping
leading whitespace, etc.

=cut

sub find_not_cclass($class_name, $str, *%opts) {
	my $offset	:= %opts<offset>;
	
	unless $offset {
		$offset := 0;
	}
	
	my $count	:= %opts<count>;
	
	unless $count {
		$count := length($str) - $offset;
	}
	
	my $class := 0 + %Cclass_id{$class_name};

	#NOTE("class = ", $class_name, "(", $class, "), offset = ", $offset, ", count = ", $count, ", str = ", $str);
	
	my $result := Q:PIR {
		$P0 = find_lex '$class'
		$I1 = $P0
		$P0 = find_lex '$str'
		$S2 = $P0
		$P0 = find_lex '$offset'
		$I3 = $P0
		$P0 = find_lex '$count'
		$I4 = $P0
		$I0 = find_not_cclass $I1, $S2, $I3, $I4
		%r = box $I0
	};
	
	#NOTE("Result = ", $result);
	return $result;
}

sub index($haystack, $needle, *%opts) {
	my $offset := 0 + %opts<offset>;
	
	my $result := Q:PIR {
		.local string haystack		
		$P0 = find_lex '$haystack'
		haystack = $P0
		
		.local string needle
		$P0 = find_lex '$needle'
		needle = $P0
		
		.local int offset
		$P0 = find_lex '$offset'
		offset = $P0
		
		$I0 = index haystack, needle, offset
		%r = box $I0
	};
	
	return $result;
}

sub is_cclass($class_name, $str, *%opts) {
	my $offset	:= 0 + %opts<offset>;
	my $class	:= 0 + %Cclass_id{$class_name};
	
	NOTE("class = ", $class_name, "(", $class, "), offset = ", $offset, ", str = ", $str);
	
	my $result := Q:PIR {
		$P0 = find_lex '$class'
		$I1 = $P0
		$P0 = find_lex '$str'
		$S2 = $P0
		$P0 = find_lex '$offset'
		$I3 = $P0
		$I0 = is_cclass $I1, $S2, $I3
		%r = box $I0
	};
	
	NOTE("Result = ", $result);
	return $result;
}

sub length($str, *%opts) {
	my $offset	:= 0 + %opts<offset>;
	NOTE("Computing length of string beyond offset ", $offset);
	DUMP($str);
	
	my $result	:= Q:PIR {
		$P0 = find_lex '$str'
		$S0 = $P0
		$I0 = length $S0
		%r = box $I0
	};

	if $offset > $result {
		$offset := $result;
	}
	
	$result := $result - $offset;
	
	NOTE("Result = ", $result);
	return $result;
}

our %Line_number_info;

sub line_number_of($string, *%opts) {
	DUMP(:string($string), :options(%opts));

	unless $string {
		NOTE("String is empty or undef. Returning 1");
		return 1;
	}
	
	my $offset := 0 + %opts<offset>;
	
	unless %Line_number_info{$string} {
		NOTE("Initializing line-number information of previously-unseen string");
		DUMP($string);
		
		my @lines := Array::empty();
		my $len := String::length($string);
		my $i := -1;
		
		while $i < $len {
			$i := String::find_cclass('NEWLINE', $string, :offset($i + 1));
			@lines.push($i);
		}
		
		%Line_number_info{$string} := @lines;
		NOTE("String parsed into ", +@lines, " lines");
		DUMP(@lines);
	}
	
	NOTE("Bsearching for line number of ", $offset, " in string");
	
	my $line := Array::bsearch(%Line_number_info{$string}, $offset, :cmp('<=>'));
	
	if $line < 0 {
		# Likely case - token is between the newlines.
		$line := (-$line) - 1;
	}
	
	$line++;
	NOTE("Returning line number (1-based): ", $line);
	return $line;
}

sub ltrim_indent($str, $indent) {
	my $limit := find_not_cclass('WHITESPACE', $str);
	
	my $i := 0;
	my $prefix := 0;
	
	while $i < $limit && $prefix < $indent {
		if char_at($str, $i) eq "\t" {
			$prefix := $prefix + 8 - $prefix % 8;
		}
		else {
			$prefix ++;
		}
	}
	
	return substr($str, $i);
}

sub repeat($str, $times) {
	my $result := Q:PIR {
		$P0 = find_lex '$str'
		$S0 = $P0
		$P0 = find_lex '$times'
		$I0 = $P0
		$S1 = repeat $S0, $I0
		%r = box $S1
	};
	
	return $result;
}

sub split($delim, $str) {
	#NOTE("delim = '", $delim, "', str = ", $str);
	
	my @array := Q:PIR {
		$P0 = find_lex '$delim'
		$S0 = $P0
		$P1 = find_lex '$str'
		$S1 = $P1
		%r = split $S0, $S1
	};
	
	#DUMP(@array);
	return @array;
}

sub substr($str, $start, *@rest) {
	my $len	:= length($str);
	
	if $start < 0 {
		$start := $start + $len;
	}
	
	if $start > $len {
		$start	:= $len;
	}

	$len := $len - $start;
	
	my $limit := $len;
	
	if +@rest {
		$limit := @rest.shift();
		
		if $limit < 0 {
			$limit := $limit + $len;
		}
		
		if $limit > $len {
			$limit := $len;
		}
	}

	my $result := Q:PIR {
		$P0 = find_lex '$str'
		$S0 = $P0
		$P0 = find_lex '$start'
		$I0 = $P0
		$P0 = find_lex '$limit'
		$I1 = $P0
		$S1 = substr $S0, $I0, $I1
		%r = box $S1
	};
	
	return $result;
}

sub trim($str) {
	my $result	:= '';
	my $left	:= find_not_cclass('WHITESPACE', $str);
	#NOTE("$left : ", $left);
	
	my $len	:= length($str);
	#NOTE("$len  : ", $len);
	
	if $left < $len {
		my $right := $len - 1;
		
		while is_cclass('WHITESPACE', $str, :offset($right)) {
			$right --;
		}
		
		#NOTE("$right: ", $right);
		
		# NB: +1 below to re-include non-ws that broke while.
		$result := substr($str, $left, $right - $left + 1);
	}
	
	#NOTE("result: ", $result);
	return $result;
}