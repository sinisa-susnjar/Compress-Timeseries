package Compress::Timeseries;

# ABSTRACT: compresses timeseries like data using running differences and bzip2

use Compress::Bzip2;
use Moose;
use Carp;

use Data::Dumper;

use namespace::autoclean;

# TODO: create POD
# TODO: create tests
# TODO: add error handling
# TODO: performance

has 'spec' => ( is => 'ro', isa => 'ArrayRef', lazy => 1, default => sub { [] } ) ;
has 'input' => ( is => 'ro', isa => 'Ref', lazy => 1, default => undef );
has 'output' => ( is => 'ro', isa => 'Ref', lazy => 1, default => undef );
has 'delimiter' => ( is => 'ro', isa => 'Str', default => "\t" );
# 1 => print generated diffs
# 2 => print also the conversion specs
# 3 => row-by-row debug (slow)
has 'debug' => ( is => 'rw', isa => 'Int', default => 0 );
has 'bzblocksize' => ( is => 'ro', isa => 'Int', default => 9 );
has 'bzsmall' => ( is => 'ro', isa => 'Int', default => 0 );
has 'bz' => ( is => 'ro', isa => 'Ref', lazy => 1, default => sub {
	my $self = shift;
	my $bz = Compress::Bzip2->new( -blockSize100k => $self->bzblocksize, -small => $self->bzsmall );
	# TODO: better error handling
	confess "can't create bzip2" unless $bz;
	return $bz;
});

# pre-defined transformations, user can add own with add_transform()
my %type_classes = (
	hms			=> 'Compress::Timeseries::Transform::HMS',
	float		=> 'Compress::Timeseries::Transform::Float',
	int			=> 'Compress::Timeseries::Transform::Integer',
	string		=> 'Compress::Timeseries::Transform::String',
	datetime	=> 'Compress::Timeseries::Transform::DateTime',
	timestamp	=> 'Compress::Timeseries::Transform::Timestamp',
);

# TODO: add user-defined transformations based on the Compress::Timeseries::Transform role
sub add_transform {
	my ($class, @args) = @_;
	confess "class method invoked on object" if ref $class;
	# your code
}

sub BUILD {
	my ($self, $args) = @_;
	use Data::Dumper;
	# print "BUILD: ", Dumper(\@_), "\n";
	my $spec = $args->{spec};
	# print "SPEC: ", Dumper($spec), "\n";
	my $idx = 0;
	foreach my $s (@$spec) {
		# print "S: ", Dumper($s), "\n";
		if (exists($s->{type})) {
			if (exists($type_classes{ $s->{type} })) {
				local $@;
				eval "use $type_classes{ $s->{type} }";
				confess $@ if $@;
				$s->{transform} = $type_classes{ $s->{type} }->new($s);
			} else {
				confess "unknown transformation type " . $s->{type};
			}
			$s->{idx} = $idx++;
		}
		# print "S: ", Dumper($s), "\n";
	}
	# print "SPEC: ", Dumper($spec), "\n";
}

sub diffbz {
	my ($self, $input, $output) = @_;
	print "DEBUG: diffbz($input, $output)\n" if $self->debug > 1;
	open(my $fd, "<", $input) or confess;
	$self->bz->bzopen($output, "wb");
	while (<$fd>) {
		chomp;
		my @row = split $self->delimiter;
		print "DEBUG: ROW: ", Dumper(\@row), "\n" if $self->debug > 2;
		my @data;
		while (my ($i, $s) = each @{$self->spec}) {
			push @data, $s->{transform}->write($row[$i]) if (exists $s->{transform});
		}
		my $data = join $self->delimiter, @data;
		print "$data\n" if $self->debug;
		$self->bz->bzwrite("$data\n");
	}
	$self->bz->bzclose;
	my $orig_sz = tell($fd);
	# printf "compression ratio: %.3f%%\n", ($orig_sz-$self->bz->total_out)/$orig_sz*100;
	close($fd);
	return ($orig_sz-$self->bz->total_out)/$orig_sz*100;
}	# diffbz

sub undiffbz {
	my ($self, $input, $output) = @_;
	print "DEBUG: undiffbz($input, $output)\n" if $self->debug > 1;
	$self->bz->bzopen($input, "rb");
	open(my $fd, ">", $output) or confess;
	my $line;
	while (my $sz = $self->bz->bzreadline($line)) {
		print $line if $self->debug;
		chomp $line;
		my @row = split $self->delimiter, $line;
		print "DEBUG: ROW: ", Dumper(\@row), "\n" if $self->debug > 2;
		my @data;
		foreach my $s (@{$self->spec}) {
			if (exists $s->{transform}) {
				push @data, $s->{transform}->read($row[$s->{idx}]);
			} elsif (exists $s->{derive}) {
				# FIXME: this assumes that the derived column always comes after the one it is derived
				# from - better first build the non-derived columns, then outside the foreach() loop
				# add the derived ones
				# TODO: also add a new type "constant" which saves a constant value in the compressed
				# file - we currently use "derive" for that, but this is a crutch
				push @data, $s->{derive}->(@data);
			}
			print "DEBUG: SPEC: ", Dumper($s), "\n" if $self->debug > 2;
		}
		print $fd join($self->delimiter, @data), "\n";
	}
	$self->bz->bzclose;
	close($fd);
}	# undiffbz

# Many timeseries, financial or other, have slowly changing values between subsequent rows.
# By creating differences between the columns of subsequent rows we can reduce the number
# of bytes necessary to store the same data albeit in a non human friendly format.
#
# Creating differences between subsequent rows and compressing these differences with bzip2
# can yield compression rates beyond 96% in certain cases while bzip2 by itself tops out at ~88%
# (typical compression rates are somewhere around 91-95%)
#
# If you have a large number of timeseries data files this can make quite an impact in
# disk utilisation.

# How it works:
# Let's say you have a file with this format:
# symbol date        time      open     high     low      close    volume  count  wap
# ES     2018-07-01  17:00:00  2800.00  2804.75  2799.50  2802.25  165     44     2803.45
# ES     2018-07-01  17:01:00  2801.00  2805.50  2800.50  2802.25  132     50     2803.55
# ES     2018-07-01  17:02:00  2802.00  2806.55  2800.50  2801.25  150     46     2801.33
# ...etc...
#
# each line in this file needs 2 (symbol) + 10 (date) + 8 (time) + 5 * 7 (open,high,low,close,wap)
# + 3 (volume) + 2 (count) + 10 (whitespace - 9 tabs plus newline) = 70 bytes of storage
#
# now we start the mapping / differencing
# the first row will be used as-is as we need a starting point
#
# starting with the second row:
# ES will be mapped to 0
# date: 2018-07-01 - 2018-07-01 = 0
# time: 17:01:00 - 17:00:00 = 1
# open: 2801.00*100 - 2800.00*100 = 100
# high,low,close,wap: same as open
# volume: 132-165 = -33
# count: 50-44 = 6
# after mapping / differencing the storage requirement for the second row dropped to 28 bytes,
# and for the third row to 31 bytes
#
# the differenced data would look like this
# symbol date        time      open     high     low      close    volume  count  wap
# ES     2018-07-01  17:00:00  2800.00  2804.75  2799.50  2802.25  165     44     2803.45
# 0      0           1             100       75      100        0  -33      6          10
# 0      0           1             100      105        0     -100   18     -4         222
#
# The original data would have used up 210 bytes, while the differenced one only uses 129 bytes
# for a total compression of ~38% - now imagine doing this for thousand of rows plus a final bzip2
# step and you have some real space saver for your timeseries data :-)

# my $spec = [
# 	symbol => {
# 		type => "string" # strings will be mapped to a unique id via hash
# 	},
# 	date => {
# 		type => "date",
# 		format => "%Y-%d-%m"
# 	},
# 	time => {
# 		type => "time",
# 		format => "%H:%M:%S"
# 	},
# 	open => {
# 		type => "float",
# 		precision => 2
# 	},
# 	high => {
# 		type => "float",
# 		precision => 2
# 	},
# 	low => {
# 		type => "float",
# 		precision => 2
# 	},
# 	close => {
# 		type => "float",
# 		precision => 2
# 	},
# 	volume => {
# 		type => "int"
# 	},
# 	count => {
# 		type => "int"
# 	},
# 	wap => {
# 		type => "float",
# 		precision => 2
# 	},
# ];
# 
# my $t = Compress::Timeseries->new(spec => $spec);
# 
# # using filenames
# $t->compress(input => "data.txt", output => "data.txt.bz2");
# 
# # using scalar strings containing the data
# my ($in, $out);
# $t->compress(input => $in, output => $out);
# 
# # using file descriptors 
# my ($ifd, $ofd);
# $t->compress(input => $ifd, output => $ofd);
# 
# # they also can be mixed
# $t->compress(input => "data.txt", output => $ofd);
# 
# # same for uncompress
# # using filenames
# $t->uncompress(input => "data.txt.bz2", output => "data.txt");
# 
# # they also can be mixed
# $t->uncompress(input => $in, output => $ofd);

__PACKAGE__->meta->make_immutable;

1;
