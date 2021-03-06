use v5.14;
use warnings;

package Pantry::App::Command::delete;
# ABSTRACT: Implements pantry delete subcommand
# VERSION

use Pantry::App -command;
use autodie;
use IO::Prompt::Tiny;
use namespace::clean;

sub abstract {
  return 'Delete an item in a pantry (nodes, roles, etc.)';
}

sub command_type {
  return 'TARGET';
}

sub options {
  my ($self) = @_;
  return (
    ['force|f', "force deletion without confirmation"],
  );
}

my @types = qw/node role environment bag/;

sub valid_types {
  return @types;
}

for my $t ( @types ) {
  no strict 'refs';
  *{"_delete_$t"} = sub {
    my ($self, $opt, $name) = @_;
    $self->_delete_obj($opt, $t, $name);
  };
}

sub _delete_obj {
  my ($self, $opt, $type, $name) = @_;

  my $options;
  $options->{env} = $opt->{env} if $opt->{env};
  my $obj = $self->_check_name($type, $name, $options);

  unless ( $opt->{force} ) {
    my $confirm = IO::Prompt::Tiny::prompt("Delete $type '$name'?", "no");
    unless ($confirm =~ /^y(?:es)?$/i) {
      print "$name will not be deleted\n";
      exit 0;
    }
  }

  unlink $obj->path;

  return;
}

1;

=for Pod::Coverage options validate

=head1 SYNOPSIS

  $ pantry create node foo.example.com

=head1 DESCRIPTION

This class implements the C<pantry create> command, which is used to create a new node data file
in a pantry.

=cut

# vim: ts=2 sts=2 sw=2 et:
