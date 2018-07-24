package Compress::Timeseries::Transform::DateTime;

use DateTime::Format::Strptime;
use DateTime;
use Moose;

has 'pattern'	=> ( is => 'ro', isa => 'Str', default => '%Y-%m-%d %H:%M:%S' );
has 'format'	=> ( is => 'ro', isa => 'Ref', lazy => 1, default => sub {
	my $self = shift;
	return DateTime::Format::Strptime->new(pattern => $self->pattern);
});

with 'Compress::Timeseries::Transform';

sub read {
	my ($self, $rc) = @_;
	$rc += $self->last if defined $self->last;
	$rc = $self->format->format_datetime( DateTime->from_epoch(epoch => $rc) );
	$self->_set_last( $self->last + $_[1] );
	return $rc;
}

sub write {
	my ($self, $rc) = @_;
	my $epoch = $self->format->parse_datetime($rc)->epoch;
	$rc = $epoch;
	$rc -= $self->last if defined $self->last;
	$self->_set_last( $epoch );
	return $rc;
}

__PACKAGE__->meta->make_immutable;

1;
