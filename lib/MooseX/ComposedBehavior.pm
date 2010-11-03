use strict;
use warnings;
package MooseX::ComposedBehavior;

use MooseX::ComposedBehavior::Stub;

use Sub::Exporter -setup => {
  groups => [ compose => \'_build_composed_behavior' ],
};

my $i = 0;

sub _build_composed_behavior {
  my ($self, $name, $arg, $col) = @_;

  my %sub;

  my $method_name = 'MooseX_ComposedBehavior_' . $i++;
  my $sugar_name  = $arg->{sugar_name};

  my $role = MooseX::ComposedBehavior::Stub->meta->generate_role(
    parameters => {
      stub_method_name => $method_name,
      compositor       => $arg->{compositor},
      method_name      => $arg->{method_name},
      also_compose     => $arg->{also_compose},
    },
  );

  my $import = Sub::Exporter::build_exporter({
    groups  => [ default => [ $sugar_name ] ],
    exports => {
      $sugar_name => sub {
        my ($self, $name, $arg, $col) = @_;
        my $target = $col->{INIT}{target};
        return sub (&) {
          my ($code) = shift;

          Moose::Util::add_method_modifier(
            $target->meta,
            'around',
            [
              $method_name,
              sub {
                my ($orig, $self, $arg, $col) = @_;
                my @array;
                push @array, (wantarray
                  ? $self->$code(@$arg)
                  : scalar $self->$code(@$arg)
                );
                push @$col, wantarray ? \@array : $array[0];
                $self->$orig($arg, $col);
              },
            ],
          );
        }
      },
    },
    collectors => {
      INIT => sub {
        $_[0] = { target => $_[1]{into} };
        Moose::Util::apply_all_roles($_[1]{into}, $role);
        return 1;
      },
    },
  });
  
  $sub{import} = $import;

  return \%sub;
}

# with in class == apply_all_roles($class, @roles)
# with in role  == apply_all_roles($role,  @roles)



1;