use strict;
use warnings;

use MARC::Leader;
use MARC::Field008;
use Test::More 'tests' => 13;
use Test::NoWarnings;

# Test.
## cnb000000096
my $leader = MARC::Leader->new->parse('     nam a22        4500');
my $obj = MARC::Field008->new(
	'leader' => $leader,
);
my $ret = $obj->parse('830304s1982    xr a         u0|0 | cze');
isa_ok($ret, 'Data::MARC::Field008');
is($ret->cataloging_source, ' ', 'Get cataloging source ( ).');
is($ret->date_entered_on_file, '830304', 'Get date entered on file (830304).');
is($ret->date1, '1982', 'Get date1 (1982).');
is($ret->date2, '    ', 'Get date2 (    ).');
is($ret->language, 'cze', 'Get language (cze).');
isa_ok($ret->material, 'Data::MARC::Field008::Book');
is($ret->material_type, 'book', 'Get material type (book).');
is($ret->modified_record, ' ', 'Get modified record ( ).');
is($ret->place_of_publication, 'xr ', 'Get place of publication (xr ).');
is($ret->raw, '830304s1982    xr a         u0|0 | cze  ', 'Get raw (830304s1982    xr a         u0|0 | cze  ).');
is($ret->type_of_date, 's', 'Get type of date (s).');
