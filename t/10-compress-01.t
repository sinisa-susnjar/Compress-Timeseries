use strict;
use warnings;

use Test::More;
use File::Compare;

use_ok('Compress::Timeseries');

my $spec = [
	{ # HH:MM:SS
		type => "hms"
	},
	{ # HH:MM
		derive => sub { # derived columns will not be written
			substr($_[0], 0, 5); # copy HH:MM
		}
	},
	{ # bid
		type => "float",
		precision => 3
	},
	{ # ask
		type => "float",
		precision => 3
	},
	{ # mid
		derive => sub { # derived columns will not be written
			sprintf "%.3f", ($_[2]+$_[3])/2;
		}
	},
	{ # broker
		type => "string"
	},
];

my $t = Compress::Timeseries->new(spec => $spec, delimiter => " ");

cmp_ok($t->diffbz("t/feed_file.txt", "t/feed_file.txt.bz2"), ">=", 96.63, 'compression rate should be >= 96.63%');

is (compare("t/feed_file.txt.bz2", "t/feed_file.txt.bz2.orig"), 0, 'compressed files should be identical');

done_testing;
