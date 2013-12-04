package FrenchFry::Util;

sub _attr {
    my ( $obj, $method, $param ) = @_;

    return $obj->{$method} unless defined $param;

    $obj->{$method} = $param;
}

1;
__END__

=head1 SYSNOPSIS

    package FrenchFry::Meta;

    use FrenchFry::Util;

    sub new {
        my ( $class, %params ) = @_;

        return bless \%params, $class;
    }

    sub title    { FrenchFry::Util::_attr( $_[0], 'title',    $_[1] ) }
    sub category { FrenchFry::Util::_attr( $_[0], 'category', $_[1] ) }
    sub author   { FrenchFry::Util::_attr( $_[0], 'author',   $_[1] ) }
    sub date     { FrenchFry::Util::_attr( $_[0], 'date',     $_[1] ) }
    sub tags     { FrenchFry::Util::_attr( $_[0], 'tags',     $_[1] ) }
