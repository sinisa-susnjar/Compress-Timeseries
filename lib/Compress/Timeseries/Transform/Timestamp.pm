package Compress::Timeseries::Transform::Timestamp;

use DateTime::Format::Strptime;
use DateTime;
use Moose;

has 'pattern'	=> ( is => 'ro', isa => 'Str', default => '%Y-%m-%d %H:%M:%S.%6N' );
has 'format'	=> ( is => 'ro', isa => 'Ref', lazy => 1, default => sub {
	my $self = shift;
	return DateTime::Format::Strptime->new(pattern => $self->pattern);
});
has 'length'	=> (is => 'ro', isa => 'Int', lazy => 1, default => sub {
	# FIXME: ensure 'format' above is initialised before 'length'
	my $self = shift;
	# return 26;
	return length($self->format->format_datetime(DateTime->now));
});
has 'precision'	=> ( is => 'ro', isa => 'Int', lazy => 1, default => sub {
	my $self = shift;
	my ($prec) = ($self->pattern =~ /%(\d)N/);
	return $prec;
});
# has 'dt'		=> ( is => 'rw', isa => 'Ref', lazy => 1, default => sub {
# 	my $self = shift;
# 	return DateTime->now;
# });
has 'trailing'	=> ( is => 'ro', isa => 'Bool', default => 0 );

with 'Compress::Timeseries::Transform';

sub read {
	my ($self, $rc) = @_;
	$rc += $self->last if defined $self->last;
	# my $epoch = int($rc / (10 ** 6));
	# my $sub = $rc - $epoch * 10 ** 6;
	# $epoch = sprintf "%.6f", $epoch + $sub / (10 ** 6) ;

	# FIXME: when passing a float as epoch to DateTime->from_epoch it does the following:
	# my ( $int, $dec ) = $epoch =~ /^(-?\d+)?(\.\d+)?/;
	# use constant MAX_NANOSECONDS => 1_000_000_000;
	# my $nanosecond = int( $dec * MAX_NANOSECONDS );
	# the last statement sometimes yields the wrong number by -1 nanosecond which shows as diff
	# in the decompressed file
	# NOTE: either use bignum, or create a "straight" unix epoch DateTime and add
	# a nanosecond duration to it
	# print "DEBUG: epoch: $epoch, int: $int, dec: $dec, nano: $nanosecond, nano2: $nanosecond2\n";
	# $epoch += $diff;
	if (1) { # use bignum
		use bignum lib => 'GMP';
		my $epoch = $rc / (10 ** $self->precision);
		$epoch += 0.000000001;
		my $dt = DateTime->from_epoch(epoch => $epoch);
		$rc = $self->format->format_datetime($dt);

#		if (!defined $self->last) {
#			my $epoch = $rc / (10 ** $self->precision);
#			$epoch += 0.000000001;
#			my $dt = DateTime->from_epoch(epoch => $epoch);
#			$self->dt( $dt );
#		} else {
#			$self->dt->add( nanoseconds => $_[1] );
#		}
#		$rc = $self->format->format_datetime($self->dt);
		no bignum;
	} else { # use datetime + duration
		use feature 'state';
		my $epoch = sprintf "%.*f", $self->precision, $rc / (10 ** $self->precision);
		state %dates;
		my ( $int, $dec ) = $epoch =~ /^(-?\d+)?\.(\d+)?/;
		if (!exists($dates{$int})) {
			$dates{$int} = DateTime->from_epoch(epoch => $int);
		}
		my $dt = $dates{$int};
		state %nanos;
		if (!exists($nanos{$dec})) {
			$nanos{$dec} = DateTime::Duration->new(nanoseconds => $dec * 1000);
		}
		my $dur = $nanos{$dec};
		$dt += $dur;
		$rc = $self->format->format_datetime($dt);
		# print "DEBUG: timestamp.transform: $_[0] => ($int, $dec) => $rc\n";
	}
	$self->_set_last( $self->last + $_[1] );
	$rc =~ s/0+$// unless $self->trailing;
	return $rc;
}

sub write {
	my ($self, $ts) = @_;
	my $len = length($ts);
	$ts .= "0" x ($self->length - $len) if $len < $self->length; # pad with 0 to get required subsecond length
	my $dt = $self->format->parse_datetime($ts);
	# my $nano = $dt->nanosecond;
	my $micro = $dt->microsecond;
	my $epoch = $dt->epoch * 10 ** $self->precision + $micro;
	my $rc = $epoch;
	# print "DEBUG: timestamp.transform($ts): $epoch: $rc\n";
	$rc -= $self->last if defined $self->last;
	$self->_set_last( $epoch );
	return $rc;
}

__PACKAGE__->meta->make_immutable;

1;
