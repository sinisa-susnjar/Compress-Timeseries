package Compress::Timeseries::Transform;

use Moose::Role;

has 'last'	=> ( is => 'ro', isa => 'Int', writer => '_set_last', default => 0 );

requires qw(read write);

1;
