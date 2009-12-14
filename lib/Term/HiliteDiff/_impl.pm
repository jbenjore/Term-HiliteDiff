package Term::HiliteDiff::_impl;
use strict;
use Carp ();

use constant _previous_input => 0;
sub new {
    my @self;
    $self[_previous_input] = undef;

    return bless \ @self, $_[0];
}

sub hilite_diff {
    # Arguments:
    #  0: self
    #  1: input string or arrayref

    return $_[0]->_do_diff( $_[1], 0 );
}

sub watch {
    # Arguments:
    #  0: self
    #  1: input string or arrayref

    return $_[0]->_do_diff( $_[1], 1 );
}

# This library uses the following ANSI escape codes
# \e[s   Save a cursor position
# \e[u   Go back to the saved cursor position
# \e[K   Erase everything from the cursor to the end of the line
# \e[31m Red
# \e[32m Green
# \e[33m Yellow
# \e[0m  Turns off all formatting

sub _parse_input {
    # Arguments:
    #  0: self
    #  1: array mode
    #  2: input string
    #
    # Returns:
    #  input arrayref, separator

    if ( $_[1] ) {
	return $_[2], "\t";
    }
    elsif ( -1 != index( $_[2], "\t" ) ) {
	return [ split /\t/, $_[2], -1 ], "\t";
    }
    elsif ( -1 != index( $_[2], "\|" ) ) {
        return [ split /\|/, $_[2], -1 ], '|';
    }
    elsif ( -1 != index( $_[2], "\n" ) ) {
	return [ split /\n/, $_[2], -1 ], "\e[K\n";
    }
    else {
        return [ split ' ', $_[2], -1 ], ' ';
    }
}

sub _color {
    # Arguments:
    #  0: input hunk
    #  1: ANSI color code
    #  2: redraw mode?

    # Color the region
    no warnings 'uninitialized';
    my $val = "\e[$_[1]m$_[0]\e[0m";

    # Turn off coloring over newlines
    $val =~ s/\n/\e[0m\n\e[$_[1]m/g;

    # Remove empty colored regions
    $val =~ s/\e\[$_[1]m\e\[0m//g;

    return $val;
}

# sdiff does the primary markup work for this module. Everything else
# just riffs on this.

sub _sdiff {
    # Arguments:
    #  0: previous input arrayref
    #  1: input arrayref
    #  2: redraw?: 

    my $prev_max_index = $#{$_[0]};
    my $new_max_index  = $#{$_[1]};
    my $max_index =
        $prev_max_index >= $new_max_index
        ? $prev_max_index
        : $new_max_index;

    my @sdiff;
    $#sdiff = $max_index;
    for my $idx ( 0 .. $max_index ) {

	no warnings 'uninitialized';
        if ( $_[0][$idx] eq $_[1][$idx] ) {
	    $sdiff[$idx] = $_[1][$idx];
	}
	else {
	    $sdiff[$idx] = _color( $_[1][$idx], 7, $_[2] );
	}
	$sdiff[$idx] = '' unless defined $sdiff[$idx];
    }
    
    return \ @sdiff;
}

sub _do_diff {
    # Arguments:
    #  0: self
    #  1: input string or arrayref
    #  2: redraw mode?

    # We accept either an array and then we don't parse it or we
    # accept a string and we try to parse it.
    my $array_mode = 'ARRAY' eq ref $_[1];

    # Interpret input
    my ( $input, $separator ) =
        $_[0]->_parse_input(
            $array_mode,
            $_[1]
        );

    # Fetch previous input
    my $prev_input =
        $_[0][_previous_input]
        || $input;

    # Diff it
    my $sdiff = _sdiff(
        $prev_input,
        $input,
        $_[2],
    );

    # Manage redrawing over the same place on the screen
    if ( $_[2] ) {
	if ( ! $_[0][_previous_input] ) {

	    # Save the cursor position
	    $sdiff->[0] = "\e[s$sdiff->[0]";
	}
	else {

	    # Restore the cursor position
	    $sdiff->[0] = "\e[u$sdiff->[0]";
	}
    }

    # Save our "previous" state into the object
    $_[0][_previous_input] = $input;


    # Contextual return:
    #                  | Input type                 |                            |
    # Calling context: | Pre-parsed array           | String                     |
    # -----------------+----------------------------+----------------------------+
    # list             | \ @diff                    | join w/ $separator         |
    # -----------------+----------------------------+----------------------------+
    # scalar           | \ @diff                    | join w/ $separator         |
    # -----------------+----------------------------+----------------------------+
    # void             | print + join w/ $separator | print + join w/ $separator |
    if ( $array_mode && defined wantarray ) {

	if ( $_[2] ) {
	    for ( @$sdiff ) {
		s/(?<!\e\[K)(?=\n)/\e[K/g;
		s/(?<=\e\[K)(?:\e\[K)+//g;
	    }
	    $sdiff->[-1] =~ s/(?<!\e\[K)\z/\e[K/;
	}

	return $sdiff;
    }
    else {
	my $output =
	    join $separator,
	    @$sdiff;

	if ( $_[2] ) {
	    $output =~ s/(?<!\e\[K)(?=\n)/\e[K/g;
	    $output =~ s/(?<=\e\[K)(?:\e\[K)+//g;
	    $output =~ s/(?<!\e\[K)\z/\e[K/;
	}

	if ( defined wantarray ) {
	    return $output;
	}
	else {
	    print $output
		or Carp::carp( "Can't write: $!" );
	}
    }
}

# Blatantly copied this from errantstory.com
q[Wow, you're pretty uptight for a guy who worships a multi-armed, hermaphrodite embodiment of destruction who has a fetish for vaguely phallic shaped headgear.];
