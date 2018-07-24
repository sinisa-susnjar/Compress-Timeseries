use strict;
use warnings;

use Test::More;

use_ok('Compress::Timeseries');
use_ok('Compress::Timeseries::Transform');
use_ok('Compress::Timeseries::Transform::String');
use_ok('Compress::Timeseries::Transform::Float');
use_ok('Compress::Timeseries::Transform::Integer');
use_ok('Compress::Timeseries::Transform::HMS');
use_ok('Compress::Timeseries::Transform::DateTime');
use_ok('Compress::Timeseries::Transform::Timestamp');

done_testing;
