package Compress::Timeseries::Transform::Float;

use Moose;

# how many decimal places after the decimal point to take into account
has 'precision'	=> ( is => 'ro', isa => 'Num', default => 2 );
# if the number of decimal places is required when decompressing, i.e. if 2700.00 can be written as 2700
has 'required'	=> ( is => 'ro', isa => 'Bool', default => 0 );
# for shifting decimal point
has 'factor'	=> ( is => 'ro', isa => 'Num', lazy => 1, default => sub {
	my $self = shift;
	return 10 ** $self->precision;
});

with 'Compress::Timeseries::Transform';

sub read {
	my ($self, $rc) = @_;
	$rc += $self->last if defined $self->last;
	$rc /= $self->factor;
	$self->_set_last( $self->last + $_[1]);
	return $self->required ? sprintf "%.*f", $self->precision, $rc : $rc;
}

sub write {
	my ($self, $val) = @_;
	$val *= $self->factor;
	my $rc = $val;
	$rc -= $self->last if defined $self->last;
	$self->_set_last( $val );
	return $rc;
}

__PACKAGE__->meta->make_immutable;

1;
