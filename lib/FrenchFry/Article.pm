package FrenchFry::Article;

use utf8;
use strict;
use warnings;

use Path::Tiny;

sub new {
    my ( $class, %params ) = @_;

    my $content = delete $params{content};

    my $obj = bless \%params, $class;
    if ($content) {
        die "meta is needed to write content\n" unless $obj->meta;
        $obj->content($content);
    }

    return $obj;
}

sub meta { FrenchFry::Util::_attr( $_[0], 'meta', $_[1] ) }

sub content {
    my ( $self, $content ) = @_;

    my $p = path( $self->meta->{content} );
    $p->spew_utf8($content) if defined $content;

    return $p->slurp_utf8;
}

1;
__END__

=head1 SYSNOPSIS

    use FrenchFry::Article;

    my $article = FrenchFry::Article->new;
    my $article = FrenchFry::Article->new(
        meta => FrenchFry::Meta->new(
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
        ),
    );
    my $article = FrenchFry::Article->new(
        meta    => $meta,
        content => 'blah blah blah...',
    );

    my $meta    = $article->meta;
    my $content = $article->content;

    $article->meta($meta);
    $article->content($content);
