package MARC::Field008;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Data::MARC::Field008;
use Data::MARC::Field008::Book;
use Data::MARC::Field008::ComputerFile;
use Data::MARC::Field008::ContinuingResource;
use Data::MARC::Field008::Map;
use Data::MARC::Field008::MixedMaterial;
use Data::MARC::Field008::Music;
use Data::MARC::Field008::VisualMaterial;
use Error::Pure qw(err);
use List::Util 1.33 qw(any);
use Mo::utils 0.08 qw(check_bool check_isa check_required);
use Scalar::Util qw(blessed);

our $VERSION = 0.01;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Leader.
	$self->{'leader'} = undef;

	# Verbose mode.
	$self->{'verbose'} = 0;

	# Process parameters.
	set_params($self, @params);

	# Check 'leader'.
	check_required($self, 'leader');
	check_isa($self, 'leader', 'Data::MARC::Leader');

	# Check 'verbose'.
	check_bool($self, 'verbose');

	return $self;
}

sub parse {
	my ($self, $field_008) = @_;

	# XXX Fix white space issue in MARC XML record.
	if (length($field_008) < 40) {
		$field_008 .= (' ' x (40 - length($field_008)));
	}

	# Check length.
	if (length($field_008) > 40) {
		err 'Bad length of MARC 008 field.',
			'Length', length($field_008),
		;
	}
	if ($self->{'verbose'}) {
		print "Field 008: |$field_008|\n";
	}

	my %params = (
		'raw' => $field_008,

		'date_entered_on_file' => (substr $field_008, 0, 6),
		'type_of_date' => (substr $field_008, 6, 1),
		'date1' => (substr $field_008, 7, 4),
		'date2' => (substr $field_008, 11, 4),
		'place_of_publication' => (substr $field_008, 15, 3),
		$self->_parse_different($field_008),
		'language' => (substr $field_008, 35, 3),
		'modified_record' => (substr $field_008, 38, 1),
		'cataloging_resource' => (substr $field_008, 39, 1),
	);

	return Data::MARC::Field008->new(%params);
}

sub serialize {
	my ($self, $field_008_obj) = @_;

	# Check object.
	if (! blessed($field_008_obj) || ! $field_008_obj->isa('Data::MARC::Field008')) {
		err "Bad 'Data::MARC::Field008' instance to serialize.";
	}

	my $field_008 = $field_008_obj->date_entered_on_file.
		$field_008_obj->type_of_date.
		$field_008_obj->date1.
		$field_008_obj->date2.
		$field_008_obj->place_of_publication.
		$self->_serialize_different($field_008_obj->material).
		$field_008_obj->language.
		$field_008_obj->modified_record.
		$field_008_obj->cataloging_resource;

	return $field_008;
}

sub _parse_different {
	my ($self, $field_008) = @_;

	my %params;

	# Book
	if ((any { $self->{'leader'}->type eq $_ } qw(a t))
		&& (any { $self->{'leader'}->bibliographic_level eq $_ } qw(a c d m))) {

		my %mat_params = (
			'illustrations' => substr($field_008, 18, 4),
			'target_audience' => substr($field_008, 22, 1),
			'form_of_item' => substr($field_008, 23, 1),
			'nature_of_content' => substr($field_008, 24, 4),
			'government_publication' => substr($field_008, 28, 1),
			'conference_publication' => substr($field_008, 29, 1),
			'festschrift' => substr($field_008, 30, 1),
			'index' => substr($field_008, 31, 1),
			'literary_form' => substr($field_008, 33, 1),
			'biography' => substr($field_008, 34, 1),

			'raw' => substr($field_008, 18, 16),
		);
		my $material = Data::MARC::Field008::Book->new(%mat_params);
		%params = (
			'material' => $material,
			'material_type' => 'book',
		);

	# Computer files.
	} elsif ($self->{'leader'}->type eq 'm') {
		my %mat_params = (
			'target_audience' => substr($field_008, 22, 1),
			'form_of_item' => substr($field_008, 23, 1),
			'type_of_computer_file' => substr($field_008, 26, 1),
			'government_publication' => substr($field_008, 28, 1),

			'raw' => substr($field_008, 18, 16),
		);
		my $material = Data::MARC::Field008::ComputerFile->new(%mat_params);
		%params = (
			'material' => $material,
			'material_type' => 'computer_file',
		);

	# Maps.
	} elsif (any { $self->{'leader'}->type eq $_ } qw(e f)) {
		my %mat_params = (
			'relief' => substr($field_008, 18, 4),
			'projection' => substr($field_008, 22, 2),
			'type_of_cartographic_material' => substr($field_008, 25, 1),
			'government_publication' => substr($field_008, 28, 1),
			'form_of_item' => substr($field_008, 29, 1),
			'index' => substr($field_008, 31, 1),
			'special_format_characteristics' => substr($field_008, 33, 2),

			'raw' => substr($field_008, 18, 16),
		);
		my $material = Data::MARC::Field008::Map->new(%mat_params);
		%params = (
			'material' => $material,
			'material_type' => 'map',
		);

	# Music.
	} elsif (any { $self->{'leader'}->type eq $_ } qw(c d i j)) {
		my %mat_params = (
			'form_of_composition' => substr($field_008, 18, 2),
			'format_of_music' => substr($field_008, 20, 1),
			'music_parts' => substr($field_008, 21, 1),
			'target_audience' => substr($field_008, 22, 1),
			'form_of_item' => substr($field_008, 23, 1),
			'accompanying_matter' => substr($field_008, 24, 6),
			'literary_text_for_sound_recordings' => substr($field_008, 30, 2),
			'transposition_and_arrangement' => substr($field_008, 33, 1),

			'raw' => substr($field_008, 18, 16),
		);
		my $material = Data::MARC::Field008::Music->new(%mat_params);
		%params = (
			'material' => $material,
			'material_type' => 'music',
		);

	# Continuing Resources
	} elsif ($self->{'leader'}->type eq 'a'
		&& (any { $self->{'leader'}->bibliographic_level eq $_ } qw(b i s))) {

		my %mat_params = (
			'frequency' => substr($field_008, 18, 1),
			'regularity' => substr($field_008, 19, 1),
			'type_of_continuing_resource' => substr($field_008, 21, 1),
			'form_of_original_item' => substr($field_008, 22, 1),
			'form_of_item' => substr($field_008, 23, 1),
			'nature_of_entire_work' => substr($field_008, 24, 1),
			'nature_of_content' => substr($field_008, 25, 3),
			'government_publication' => substr($field_008, 28, 1),
			'conference_publication' => substr($field_008, 29, 1),
			'original_alphabet_or_script_of_title' => substr($field_008, 33, 1),
			'entry_convention' => substr($field_008, 34, 1),

			'raw' => substr($field_008, 18, 16),
		);
		my $material = Data::MARC::Field008::ContinuingResource->new(%mat_params);
		%params = (
			'material' => $material,
			'material_type' => 'continuing_resource',
		);

	# Visual Materials
	} elsif (any { $self->{'leader'}->type eq $_ } qw(g k o r)) {
		my %mat_params = (
			'running_time_for_motion_pictures_and_videorecordings' => substr($field_008, 18, 3),
			'target_audience' => substr($field_008, 22, 1),
			'government_publication' => substr($field_008, 28, 1),
			'form_of_item' => substr($field_008, 29, 1),
			'type_of_visual_material' => substr($field_008, 33, 1),
			'technique' => substr($field_008, 34, 1),

			'raw' => substr($field_008, 18, 16),
		);
		my $material = Data::MARC::Field008::VisualMaterial->new(%mat_params);
		%params = (
			'material' => $material,
			'material_type' => 'visual_material',
		);

	# Mixed Materials
	} elsif ($self->{'leader'}->type eq 'p') {
		my %mat_params = (
			'form_of_item' => substr($field_008, 23, 1),

			'raw' => substr($field_008, 18, 16),
		);
		my $material = Data::MARC::Field008::MixedMaterial->new(%mat_params);
		%params = (
			'material' => $material,
			'material_type' => 'mixed_material',
		);

	} else {
		err "Unsupported 008 type.";
	}

	return %params;
}

sub _serialize_different {
	my ($self, $material) = @_;

	# Book
	# TODO Remove
	my $ret = (' ' x 16);
	if ($material->isa('Data::MARC::Field008::Book')) {
		# TODO
	} elsif ($material->isa('Data::MARC::Field008::ComputerFile')) {
		# TODO
	} elsif ($material->isa('Data::MARC::Field008::ContinuingResource')) {
		# TODO
	} elsif ($material->isa('Data::MARC::Field008::Map')) {
		# TODO
	} elsif ($material->isa('Data::MARC::Field008::MixedMaterial')) {
		$ret = (' ' x 5).$material->form_of_item.(' ' x 10);
	} elsif ($material->isa('Data::MARC::Field008::Music')) {
		# TODO
	} elsif ($material->isa('Data::MARC::Field008::VisualMaterial')) {
		# TODO
	}

	return $ret;
}

1;

__END__
