use 5.008001;
use strict;
use warnings;

package Pantry::Model::Environment;
# ABSTRACT: Pantry data model for Chef environments
# VERSION

use Moose 2;
use MooseX::Types::Path::Class::MoreCoercions qw/File/;
use List::AllUtils qw/uniq first/;
use Pantry::Model::Util qw/hash_to_dot dot_to_hash/;
use namespace::autoclean;

# new_from_file, save_as
with 'Pantry::Role::Serializable' => {
  freezer => '_freeze',
  thawer => '_thaw',
};

#--------------------------------------------------------------------------#
# Chef environment attributes
#--------------------------------------------------------------------------#

has _path => (
  is => 'ro',
  reader => 'path',
  isa => File,
  coerce => 1,
  predicate => 'has_path',
);

has name => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

has description => (
  is => 'ro',
  isa => 'Str',
  lazy_build => 1,
);

sub _build_description {
  my $self = shift;
  return "The " . $self->name . " environment";
}

=attr default_attributes

This attribute holds environment default attribute data as key-value pairs.  Keys may
be separated by a period to indicate nesting (literal periods must be
escaped by a backslash).  Values should be scalars or array references.

=method set_default_attribute

  $environment->set_default_attribute("nginx.port", 80);

Sets the environment default attribute for the given key to the given value.

=method get_default_attribute

  my $port = $environment->get_default_attribute("nginx.port");

Returns the environment default attribute for the given key.

=method delete_default_attribute

  $environment->delete_default_attribute("nginx.port");

Deletes the environment default attribute for the given key.

=cut

has default_attributes => (
  is => 'ro',
  isa => 'HashRef',
  traits => ['Hash'],
  default => sub { +{} },
  handles => {
    set_default_attribute => 'set',
    get_default_attribute => 'get',
    delete_default_attribute => 'delete',
  },
);

=attr override_attributes

This attribute holds environment override attribute data as key-value pairs.  Keys may
be separated by a period to indicate nesting (literal periods must be
escaped by a backslash).  Values should be scalars or array references.

=method set_override_attribute

  $environment->set_override_attribute("nginx.port", 80);

Sets the environment override attribute for the given key to the given value.

=method get_override_attribute

  my $port = $environment->get_override_attribute("nginx.port");

Returns the environment override attribute for the given key.

=method delete_override_attribute

  $environment->delete_override_attribute("nginx.port");

Deletes the environment override attribute for the given key.

=cut

has override_attributes => (
  is => 'ro',
  isa => 'HashRef',
  traits => ['Hash'],
  default => sub { +{} },
  handles => {
    set_override_attribute => 'set',
    get_override_attribute => 'get',
    delete_override_attribute => 'delete',
  },
);

=method save

Saves the node to a file in the pantry.  If the private C<_path>
attribute has not been set, an exception is thrown.

=cut

sub save {
  my ($self) = @_;
  die "No _path attribute set" unless $self->has_path;
  return $self->save_as( $self->path );
}

my @attribute_keys = qw/default_attributes override_attributes/;

sub _freeze {
  my ($self, $data) = @_;
  for my $attr ( qw/default_attributes override_attributes/ ) {
    my $old = delete $data->{$attr};
    my $new = {};
    for my $k ( keys %$old ) {
      dot_to_hash($new, $k, $old->{$k});
    }
    $data->{$attr} = $new;
  }
  $data->{json_class} = "Chef::Environment";
  $data->{chef_type} = "environment";
  return $data;
}

sub _thaw {
  my ($self, $data) = @_;
  delete $data->{$_} for qw/json_class chef_type/;
  for my $attr ( qw/default_attributes override_attributes/ ) {
    my $old = delete $data->{$attr};
    my $new = {};
    for my $k ( keys %$old ) {
      my $v = $old->{$k};
      $k =~ s{\.}{\\.}g; # escape existing dots in key
      for my $pair ( hash_to_dot($k, $v) ) {
        my ($key, $value) = @$pair;
        $new->{$key} = $value;
      }
    }
    $data->{$attr} = $new;
  }
  return $data;
}

1;

=head1 DESCRIPTION

Under development.

=cut

# vim: ts=2 sts=2 sw=2 et:
