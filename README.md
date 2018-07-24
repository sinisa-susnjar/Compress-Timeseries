# NAME

Compress::Timeseries - Compress timeseries-like data by keeping running differences and compressing them using Compress::Bzip2

# VERSION

0.001

# SYNOPSIS

    use Compress::Timeseries;

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

    print "compressing feed_file.txt to f1.txt.bz2\n";
    $t->diffbz("feed_file.txt", "f1.txt.bz2");

    print "uncompressing f1.txt.bz2 to f1.txt\n";
    $t->undiffbz("f1.txt.bz2", "f1.txt");

# DESCRIPTION

Many timeseries, financial or other, have slowly changing values between subsequent rows.
By creating differences between the columns of subsequent rows one can reduce the number
of bytes necessary to store the same data albeit in a non human friendly format.

Creating differences between subsequent rows and compressing these differences with bzip2
can yield compression rates beyond 96% in certain cases while only bzip2 tops out at ~88% -
typical compression rates are somewhere around 91-95%.

If you have a large number of timeseries data files this can make quite an impact in
disk utilisation.

How it works:
Let's say you have a file with this format:
symbol date        time      open     high     low      close    volume  count  wap
ES     2018-07-01  17:00:00  2800.00  2804.75  2799.50  2802.25  165     44     2803.45
ES     2018-07-01  17:01:00  2801.00  2805.50  2800.50  2802.25  132     50     2803.55
ES     2018-07-01  17:02:00  2802.00  2806.55  2800.50  2801.25  150     46     2801.33
...etc...

each line in this file needs 2 (symbol) + 10 (date) + 8 (time) + 5 * 7 (open,high,low,close,wap)
+ 3 (volume) + 2 (count) + 10 (whitespace - 9 tabs plus newline) = 70 bytes of storage

now we start the mapping / differencing
the first row will be used as-is as we need a starting point

starting with the second row:

    ES will be mapped to 0
    date: 2018-07-01 - 2018-07-01 = 0
    time: 17:01:00 - 17:00:00 = 1
    open: 2801.00*100 - 2800.00*100 = 100
    high,low,close,wap: same as open
    volume: 132-165 = -33
    count: 50-44 = 6

after mapping / differencing the storage requirement for the second row dropped to 28 bytes,
and for the third row to 31 bytes

the differenced data would look like this
symbol date        time      open     high     low      close    volume  count  wap
ES     2018-07-01  17:00:00  2800.00  2804.75  2799.50  2802.25  165     44     2803.45
0      0           1             100       75      100        0  -33      6          10
0      0           1             100      105        0     -100   18     -4         222

The original data would have used up 210 bytes, while the differenced one only uses 129 bytes
for a total compression of ~38% (before bzip3) - now imagine doing this for thousand of rows
plus a final bzip2 step and you have some real space saver for your timeseries data :-)

# KNOWN ISSUES

This module is considered alpha and has many issues. Here is a non-exhaustive list:
1) using timestamps is sloooow
2) position of derived columns can only be after the columns it is derived from
3) adding user defined transformations not yet implemented
4) missing pod
5) missing tests
6) most certainly many more

# SUPPORT

Bugs may be submitted at [https://github.com/sinisa-susnjar/Compress-Timeseries/issues](https://github.com/sinisa.susnjar/Compress-Timeseries/issues).

# SOURCE

The source code repository for Compress::Timeseries can be found at [https://github.com/sinisa-susnjar/Compress-Timeseries](https://github.com/sinisa-susnjar/Compress-Timeseries).

# AUTHOR

Sinisa Susnjar <sini@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Sinisa Susnjar.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
`LICENSE` file included with this distribution.

