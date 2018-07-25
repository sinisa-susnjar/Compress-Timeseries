requires "Carp" => "0";
requires "Compress::Bzip2" => "0";
requires "Data::Dumper" => "0";
requires "DateTime" => "0";
requires "DateTime::Format::Strptime" => "0";
requires "Moose" => "0";
requires "Moose::Role" => "0";
requires "bignum" => "0";
requires "feature" => "0";
requires "namespace::autoclean" => "0";

on 'test' => sub {
  requires "File::Compare" => "0";
  requires "Test::More" => "0";
  requires "strict" => "0";
  requires "warnings" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};
