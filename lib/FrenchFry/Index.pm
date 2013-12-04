package FrenchFry::Index;

use utf8;
use strict;
use warnings;

use JSON qw();
use Path::Tiny;
use Time::Piece;

use FrenchFry::Util;

sub new {
    my ( $class, %metas ) = @_;

    return bless \%metas, $class;
}

sub new_from_json {
    my ( $class, $json_file ) = @_;

    my $self = $class->new;
    $self->from_json($json_file);

    return $self;
}

sub each {
    my ( $self, $coderef, $data ) = @_;

    for my $key ( keys %$self ) {
        $coderef->( $key, $self->{$key}, $self, $data );
    }
}

sub from_json {
    my ( $self, $json_file ) = @_;

    my $data;
    if ( !ref($json_file) ) {
        $data = JSON::from_json( path($json_file)->slurp_utf8 );
    }
    else {
        $data = JSON::from_json( $$json_file );
    }

    for my $key ( keys %$data ) {
        my $meta = $data->{$key};
        $self->{$key} = FrenchFry::Meta->new(%$meta);
    }
}

sub to_json {
    my ( $self, $json_file ) = @_;

    my %data;
    for my $key ( keys %$self ) {
        my $meta = $self->{$key};

        $data{$key} = {
            title    => $meta->title,
            category => $meta->category,
            author   => {
                name  => $meta->author->{name},
                email => $meta->author->{email},
                nick  => $meta->author->{nick},
            },
            date     => $meta->date,
            tags     => $meta->tags,
            content  => $meta->content,
        }
    }

    my $json = JSON::to_json(\%data);

    if ($json_file) {
        path($json_file)->spew($json);
    }

    return $json;
}

sub add {
    my ( $self, $id, $meta ) = @_;

    $self->{$id} = $meta;
}

sub remove {
    my ( $self, $id ) = @_;

    return delete $self->{$id};
}

sub all { keys %{$_[0]} }

sub recent_articles {
    my ( $self, $num ) = @_;

    my @result =
        reverse
        sort { $self->{$a}->date <=> $self->{$b}->date }
        keys %$self;

    return grep { defined($_) } @result[ 0 .. $num - 1 ];
}

sub recent_days {
    my ( $self, $num ) = @_;

    my $recent_day = gmtime->epoch - ( $num * 24 * 60 * 60 );
    my @result = 
        grep { $self->{$_}{date} >= $recent_day } 
        keys %$self;

    return @result;
}

sub tags {
    my $self = shift;

    my @result;
    my %tags;
    $tags{$_}++ for @_;

    for my $id (keys %$self) {
        for ( @{$self->{$id}{tags}} ) {
            push @result, $id if exists $tags{$_};
        }
    }

    return @result;
}

sub category {
    my $self     = shift;
    my $category = shift;
    my @result   =
        grep { $self->{$_} if $self->{$_}{category} eq $category }
        keys %$self;

    return @result;
}

sub author_name {
    my $self   = shift;
    my $author = shift;
    my @result =
        grep { $self->{$_} if $self->{$_}{author}{name} eq $author }
        keys %$self;

    return @result;
}

sub year {
    my ($self, $year) = @_;
    my @result;
    @result =
        grep { gmtime($self->{$_}{date})->year eq $year }
        keys %$self;

    return @result;
}

sub month {
    grep { gmtime($_[0]{$_}{date})->mon  eq $_[2] }
    grep { gmtime($_[0]{$_}{date})->year eq $_[1] }
    keys %{$_[0]};
}

sub day {
    grep { gmtime($_[0]->{$_}->{date})->mday eq $_[3] }
    grep { gmtime($_[0]->{$_}->{date})->mon  eq $_[2] }
    grep { gmtime($_[0]->{$_}->{date})->year eq $_[1] }
    keys %{$_[0]};
}

sub meta {
    my ( $self, $meta_id ) = @_;

    return $self->{$meta_id};
}

1;
__END__

=head1 SYSNOPSIS

    use FrenchFry::Index;

    my $index = FrenchFry::Index->new;
    my $index = FrenchFry::Index->new( $meta1, $meta2 );
    my $index = FrenchFry::Index->new_from_json( 'index.json' );

    $index->from_json('recent-article.json');
    $index->to_json('backup.json');

    $index->add( $id => $meta );
    my $meta = $index->remove($id);

    my @metas;
    @metas = $index->recent_articles(10);
    @metas = $index->recent_days(7);
    @metas = $index->tags( 'perl', 'life' );
    @metas = $index->author_name('Jaemin Choi');
    @metas = $index->year(2013);
    @metas = $index->month(2013, 3);
    @metas = $index->day(2013, 3, 20);
    @metas = $index->meta_id('ascii-table');
    @metas = $index->category('perl');

    #
    # articles가 완성된다면...
    #
    my @articles;
    @metas = $index->recent_articles(10);
    for my $meta (@metas) {
        my $article = FrenchFry::Article->new( meta => $meta );
        push @articles, $article;
    }
    @articles; <-- 
    for my $article (@articles) {
        say $article->meta->title;
        say $article->content;
    }
