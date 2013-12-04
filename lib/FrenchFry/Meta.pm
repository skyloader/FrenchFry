package FrenchFry::Meta;

use strict;
use warnings;

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
sub content  { FrenchFry::Util::_attr( $_[0], 'content',  $_[1] ) }

1;
__END__

=head1 SYSNOPSIS

    use FrenchFry::Meta;
    use File::Slurp;

    my $meta = FrenchFry::Meta->new(
        title    => "네모 반듯한 표 그리고 한글",
        category => "perl",
        author   => {
            name   => "Keedi Kim",
            email  => 'keedi.k@gmail.com',
            nick   => "keedi",
        },
        date    => 192939492,
        tags    => [ "kpw", "perl", "table", "한글" ],
        content => '/home/askdna/articles/2013-06-27-01.mkd',
    );

    #
    # get
    #
    say $meta->title;
    say $meta->category;
    say $meta->author->{name};
    say $meta->author->{email};
    say $meta->author->{nick};
    say $meta->date;
    say for @{ $meta->tags };
    say read_file($meta->content);

    #
    # set
    #
    $meta->title("Let's change title");
    $meta->category("text");
    $meta->author(
        name  => 'Jaemin Choi',
        email => 'skyloader@gmail.com',
        nick  => 'skyloader',
    );
    $meta->date(1371647519);
    $meta->tags([ '일상다반사', 'diary' ]);
    $meta->content('../articles/test.mkd');
