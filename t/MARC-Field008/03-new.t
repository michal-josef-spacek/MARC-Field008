use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use MARC::Leader;
use MARC::Field008;
use Test::MockObject;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $leader = MARC::Leader->new->parse('02816njm a2200697 i 4500');
my $obj = MARC::Field008->new(
	'leader' => $leader,
);
isa_ok($obj, 'MARC::Field008');

# Test.
eval {
	MARC::Field008->new;
};
is($EVAL_ERROR, "Parameter 'leader' is required.\n",
	"Parameter 'leader' is required.");
clean();

# Test.
eval {
	MARC::Field008->new(
		'leader' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'leader' must be a 'Data::MARC::Leader' object.\n",
	"Parameter 'leader' must be a 'Data::MARC::Leader' object (bad).");
clean();

# Test.
my $mock = Test::MockObject->new;
eval {
	MARC::Field008->new(
		'leader' => $mock,
	);
};
is($EVAL_ERROR, "Parameter 'leader' must be a 'Data::MARC::Leader' object.\n",
	"Parameter 'leader' must be a 'Data::MARC::Leader' object (mock object).");
clean();
