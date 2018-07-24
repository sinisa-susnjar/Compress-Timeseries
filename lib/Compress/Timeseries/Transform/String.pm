package Compress::Timeseries::Transform::String;

use Moose;

has 'map'		=> ( is => 'ro', isa => 'HashRef', lazy => 1, default => sub { {} } );
has 'id'		=> ( is => 'ro', isa => 'Int', default => 0, writer => '_set_id' );

with 'Compress::Timeseries::Transform';

sub read {
	my ($self, $str) = @_;
	my $rc;
	if ($str =~ /^\d+/) {
		$rc = $self->map->{$str};
	} else {
		$rc = $self->map->{$self->id} = $str;
		$self->_set_id( $self->id + 1 );
	}
	return $rc;
}

sub write {
	my ($self, $str) = @_;
	if (!exists($self->map->{$str})) {
		$self->map->{$str} = $self->id;
		$self->_set_id( $self->id + 1 );
		return $str;
	}
	return $self->map->{$str};
}

__PACKAGE__->meta->make_immutable;

1;
