#!/usr/bin/env perl

use 5.018;
use utf8;
use strict;
use warnings;

use JSON qw();
use List::MoreUtils qw( any );
use Path::Tiny;
use Time::Piece;

use Skyloader::Blog::Meta;
use Skyloader::Blog::Index;

use DDP;

my $jsonfile = 'blog-meta.json'; 
#my $jsonfile = 'sample1.json'; 
my $index = Skyloader::Blog::Index->new_from_json($jsonfile);

my @cmd = qw/list show remove add/;

my ( $command, $id, @attr ) = @ARGV;

if ( any { $ARGV[0] eq $_ } @cmd) {
    hashkey_listing()           if $command eq 'list';
    die 'Hashkey needed'        if $command ne 'list' and !$id;
    add_meta($id)               if $command eq 'add';
    remove_meta($id)            if $command eq 'remove';
    show_meta($id)              if $command eq 'show';
    modify_meta($id, \@attr)    if $command eq 'mod';
}
else {
    say 'Use only show, list, remove, add, mod';
}

sub show_meta { p $index->meta($_[0]) }

sub hashkey_listing {
    p $_ for sort $index->all;
}

sub remove_meta {
    my $hashkey = shift;
    $index->remove($hashkey);
    $index->to_json($jsonfile);
}

#sub modify_meta {
#    my $hashkey = shift;
#    my @attr    = @$_[0];
#
#    die "$hashkey not exist!" unless $index->{$hashkey};
#
#    my $meta = $index->meta($hashkey);
#    for my $attr (qw/title category author tag content/) {
#        unless ( any { $attr eq $_} qw/author tags/ ) {
#           $meta->$attr($attr[0]);
#        }
#        elsif ( $attr eq '') {
#
#        }
#    }
#
#
#}

sub add_meta {
    my $hashkey = shift;

    die "$hashkey already exist!" if $index->{$hashkey};
    my $meta = Skyloader::Blog::Meta->new();
    for my $attr (qw/title category author tags content/) {
        unless ( any { $attr eq $_ } qw/author tags/ ) { 
            printf('%10s : ', $attr);
            my $attr_val = <STDIN>; chomp $attr_val;
            $meta->$attr($attr_val);
        }
        elsif ( $attr eq 'author') {
            my %author_data;
            printf("%10s \n", $attr);
            for my $author_attr (qw/name email nick/) {
                printf('%12s : ', $author_attr);
                chomp( my $attr_val = <STDIN> );
                $author_data{$author_attr} = $attr_val;
            }
            $meta->author(\%author_data);
        }
        elsif ( $attr eq 'tags' ) {
            printf('%10s : ', $attr);
            my $attr_val = <STDIN>; chomp $attr_val;
            $meta->tags([split /,\s*/, $attr_val]);
        }
    }
    $meta->date(time);

    say "\nYou entered...";
    p $meta;
    $index->add($hashkey => $meta);
    $index->to_json($jsonfile);
}


__END__

=head1 SYSNOPSIS

To get hashkeys from json file

    tool.pl list
    hashkey1
    hashkey2
    ...
    hashkeylast

To get specific article metadata from hashkey

    tool.pl show ascii-table
    title   : 네모 반듯한 표 그리고 한글
    category: perl
    author  : 
        name  : Keedi Kim
        email : keedi.k@gmail.com
        nick  : keedi
    date    : 192939492,
    tags    : kpw, perl, table, 한글 
    content : /Users/jaeminchoi/workspace/blog/01.mkd 

To add specific article

    tool.pl add ascii-table
    title   : 네모 반듯한 표 그리고 한글
    category: perl
    author  : 
        name  : Keedi Kim
        email : keedi.k@gmail.com
        nick  : keedi
    date    : 192939492,
    tags    : kpw, perl, table, 한글 
    content : /Users/jaeminchoi/workspace/blog/01.mkd 

To remove specific article

    tool.pl remove ascii-table

To modify specific article metadata field

    tool.pl mod ascii-table author name Jaemin Choi
