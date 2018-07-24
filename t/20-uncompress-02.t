use strict;
use warnings;

use Test::More;
use File::Compare;

use_ok('Compress::Timeseries');

my $spec = [
	{ # 2
		derive => sub { 2 }
	},
	{ # datetime
		type => "datetime",
		pattern => "%Y-%m-%d %H:%M:%S"
	},
	{ # open
		type => "float",
		precision => 2, # precision is required, i.e. output 2701.00 as such, not as 2701
		required => 1
	},
	{ # high
		type => "float",
		precision => 2,
		required => 1
	},
	{ # low
		type => "float",
		precision => 2,
		required => 1
	},
	{ # close
		type => "float",
		precision => 2,
		required => 1
	},
	{ # volume
		type => "int",
	},
	{ # wap
		type => "float",
		precision => 2,
		required => 1
	},
	{ # count
		type => "int",
	},
];

my $t = Compress::Timeseries->new(spec => $spec);

$t->undiffbz("t/ES_1.txt.bz2", "t/ES_1.txt.1");

is (compare("t/ES_1.txt.1", "t/ES_1.txt"), 0, 'uncompressed files should be identical');

done_testing;
