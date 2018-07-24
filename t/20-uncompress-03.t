use strict;
use warnings;

use Test::More;
use File::Compare;

use_ok('Compress::Timeseries');

my $spec = [
	{ # timestamp
		type => "timestamp", # for resolutions < 1 sec
		pattern => "%Y-%m-%d %H:%M:%S.%6N", # %3N => milliseconds, %6N => microseconds, %9N => nanoseconds accuracy
		trailing => 0
	},
	{ # symbol
		derive => sub { "ES=F" }
	},
	{ # tick value
		type => "float",
		precision => 2
	},
];

my $t = Compress::Timeseries->new(spec => $spec);

$t->undiffbz("t/ticks.txt.bz2", "t/ticks.txt.1");

is (compare("t/ticks.txt.1", "t/ticks.txt"), 0, 'uncompressed files should be identical');

done_testing;
