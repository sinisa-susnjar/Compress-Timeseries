package Compress::Timeseries::Transform::Integer;

use Moose;

with 'Compress::Timeseries::Transform';

sub read {
	my ($self, $rc) = @_;
	$rc += $self->last if defined $self->last;
	$self->_set_last( $self->last + $_[1] );
	return $rc;
}

sub write {
	my ($self, $rc) = @_;
	$rc -= $self->last if defined $self->last;
	$self->_set_last( $_[1] );
	return $rc;
}

__PACKAGE__->meta->make_immutable;

1;
