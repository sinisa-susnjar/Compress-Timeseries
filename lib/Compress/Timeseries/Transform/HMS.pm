package Compress::Timeseries::Transform::HMS;

use Moose;

has 'seccache' => ( is => 'ro', isa => 'HashRef', lazy => 1, default => sub { {} } );
has 'hmscache' => ( is => 'ro', isa => 'HashRef', lazy => 1, default => sub { {} } );

with 'Compress::Timeseries::Transform';

sub read {
	my ($self, $sec) = @_;
	my $rc = $sec;
	$rc += $self->last if defined $self->last;
	$rc = $self->sec2hms($rc);
	$self->_set_last( $self->last + $sec );
	return $rc;
}

sub write {
	my ($self, $hms) = @_;
	my $sec = $self->hms2sec($hms);
	my $rc = $sec;
	$rc -= $self->last if defined $self->last;
	$self->_set_last( $sec );
	return $rc;
}

sub hms2sec {
	my ($self, $hms) = @_;
	if (!exists($self->seccache->{$hms})) {
		my ($h, $m, $s) = split ":", $hms;
		$self->seccache->{$hms} = $s + $m * 60 + $h * 3600;
	}
	return $self->seccache->{$hms};
}	# hms2sec()

sub sec2hms {
	my ($self, $sec) = @_;
	if (!exists($self->hmscache->{$sec})) {
		my $h = int($sec / 3600);
		my $m = int(($sec - $h * 3600) / 60);
		my $s = $sec - $h * 3600 - $m * 60;
		$self->hmscache->{$sec} = sprintf "%02d:%02d:%02d", $h, $m, $s;
	}
	return $self->hmscache->{$sec};
}	# sec2hms()

__PACKAGE__->meta->make_immutable;

1;
