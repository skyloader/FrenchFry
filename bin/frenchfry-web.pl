#!/usr/bin/env perl

use utf8;
use Mojolicious::Lite;
use Mojo::JSON;

use Encode qw( decode_utf8 );
use File::Slurp;
use List::MoreUtils qw( uniq );
use Text::MultiMarkdown qw( markdown );

use FrenchFry::Meta;
use FrenchFry::Index;
use FrenchFry::Article;

app->defaults( %{ plugin Config => { default => {
    categories      => [],
    recent_articles => [],
    about           => 'About FrenchFry',
    index_file      => 'frenchfry.json',
    headline        => 'Headline',
    subheadline     => 'Subheadline',
}}});

my $TMM   = Text::MultiMarkdown->new;
my $INDEX = FrenchFry::Index->new_from_json( app->config->{index_file} );

helper filter_syntax_highlight => sub {
    my ( $self, $html ) = @_;

    $html =~ s{<pre><code>#!(\w+)\n(.*?)</code></pre>}{<pre class="brush: $1">$2</pre>}gms;

    return $html;
};

helper get_summary => sub {
    my ( $self, $article ) = @_;

    my $content = substr decode_utf8($article->content), 0, 400;
    my @temp = split /\n/, $content;
    pop @temp;
    $content = join "\n", @temp;

    return $self->filter_syntax_highlight( $TMM->markdown($content) );
};

helper get_tag_articles => sub {
    my ( $self, $tag ) = @_;
    
    my @articles;
    my @meta_ids = $INDEX->tags($tag);
    for my $meta_id (@meta_ids) {  
        my $article = FrenchFry::Article->new( meta => $INDEX->meta($meta_id) );
        push (
            @articles,
            {
                meta_id => $meta_id,
                article => $article,
            },
        );
    }
    
    return @articles;
};

helper get_category_articles => sub {
    my ( $self, $category ) = @_;

    my @articles;
    my @meta_ids = $INDEX->category($category);
    for my $meta_id (@meta_ids) {
        my $article = FrenchFry::Article->new( meta => $INDEX->meta($meta_id) );
        push (
            @articles,
            {
                meta_id => $meta_id,
                article => $article,
            },
        );
    }

    return @articles;
};

helper get_categories => sub {
    my $self = shift;

    my @meta_ids = $INDEX->all;
    my @categories; 
    for my $meta_id (@meta_ids) {
        push @categories, $INDEX->meta($meta_id)->category;
    }
    @categories = uniq sort @categories;
    
    return @categories;
};

helper get_recent_articles => sub {
    my ( $self, $max ) = @_;

    my @articles;
    my @meta_ids = $INDEX->recent_articles($max);
    for my $meta_id (@meta_ids) {
        my $article = FrenchFry::Article->new( meta => $INDEX->meta($meta_id) );
        push(
            @articles,
            {
                meta_id => $meta_id,
                article => $article,
            },
        );
    }

    return @articles;
};

under sub {
    my $self = shift;

    $self->stash(
        recent_articles => [ $self->get_recent_articles(10) ],
        categories      => [ $self->get_categories ], 
    );

    return 1;
};

get '/reload' => sub {
    my $self = shift;

    $INDEX = FrenchFry::Index->new_from_json( app->config->{index_file} );
    $self->redirect_to('/');
};

get '/' => sub { shift->redirect_to('/recent') };

get '/archive' => sub {
    my $self = shift;
    
    $self->render(
        'archive',
        articles => [ $self->get_recent_articles( scalar $INDEX->all ) ],
    );
};

get '/page/:meta_id' => sub {
    my $self    = shift;

    my $meta_id = $self->param('meta_id');
    my $meta    = $INDEX->meta($meta_id);

    my $article = FrenchFry::Article->new( meta => $meta );
    my $content = $self->filter_syntax_highlight( $TMM->markdown( decode_utf8($article->content) ) );
    my $date    = gmtime( $meta->date );
    write_file( 'a.html', { binmode => ':utf8' }, $content );

    $self->render( 
        'article',
        meta    => $meta,
        content => $content,
    );
};

get '/recent';

get '/tags/:tag' => sub {
    my $self = shift;
    
    my $tag = $self->param('tag');
    $self->render(
        'archive',
        articles => [ $self->get_tag_articles($tag) ],
    );
};

get '/category/:category' => sub {
    my $self = shift;

    my $category = $self->param('category');
    $self->render(
        'archive',
        articles        => [ $self->get_category_articles($category) ],
    );
};

app->start;

__DATA__

@@ archive.html.ep
% layout 'default';
% title 'blog all articles';
  % for my $item (@$articles) {
  %     my $meta        = $item->{article}->meta;
  %     my $date        = gmtime($meta->date);
  %     my $content     = get_summary( $item->{article} );
  %     my $article_url = q[/page/] . $item->{meta_id};
  %     my $category    = $meta->category;
  <!-- Each Post -->
  <div class="entry">
     <h2><a href="<%= url_for($article_url) %>"><%= $meta->title %></a></h2>

     <!-- Meta details -->
     <div class="meta">
        <i class="icon-calendar"></i> <%= $date %> 
        <i class="icon-user"></i> <%= $meta->author->{nick} %> 
        <i class="icon-folder-open"></i> <a href="<%= url_for("/category/$category") %>"> <%= $category %> </a> 
        <span class="pull-right">
        <i class="icon-comment"></i> <a href="<%= url_for($article_url) %>#disqus_thread">Link</a>
        <br>
        <i class="icon-tag"></i> 
        % for my $tag ( @{$meta->tags} ) { 
            <a href="<%= url_for("/tags/$tag") %>"><%= $tag %></a>
        % }
        </span>
     </div>
  </div>
  % }
  
  <div class="clearfix"></div>

@@ recent.html.ep
% layout 'default';
% title 'blogging the skyloader';
  <!-- Each posts should be enclosed inside "entry" class" -->

  % for my $item (@$recent_articles) {
  %     my $meta        = $item->{article}->meta;
  %     my $date        = gmtime($meta->date);
  %     my $content     = get_summary( $item->{article} );
  %     my $article_url = q[/page/] . $item->{meta_id};
  %     my $category    = $meta->category;

  <!-- Each Post -->
  <div class="entry">
     <h2><a href="<%= url_for($article_url) %>"><%= $meta->title %></a></h2>
     
     <!-- Meta details -->
     <div class="meta">
        <i class="icon-calendar"></i> <%= $date %> 
        <i class="icon-user"></i> <%= $meta->author->{nick} %> 
        <i class="icon-folder-open"></i> <a href="<%= url_for("/category/$category") %>"> <%= $category %> </a> 
        <span class="pull-right">
        <i class="icon-comment"></i><a href="<%= url_for($article_url) %>#disqus_thread">Link</a></span>
        <br> 
        <i class="icon-tag"></i> 
        % for my $tag ( @{$meta->tags} ) { 
            <a href="<%= url_for("/tags/$tag") %>"><%= $tag %></a>
        % }
     </div>
     <%== $content %>
     <div class="button"><a href="<%= url_for($article_url) %>">Read More...</a></div>
  </div>
  % }
  
  <div class="clearfix"></div>


@@ article.html.ep
% layout 'default';
% title $meta->title;
  % my $date        = gmtime($meta->date);
  % my $category    = $meta->category;
  % my $subject     = $meta->title;
  % my $author      = $meta->author->{nick};
  % my $article_url = q[/page/] . $meta->{meta_id};

  <div class="entry">
     <h2><a href="#"><%= $subject %></a></h2>
     
     <!-- Meta details -->
     <div class="meta">
        <i class="icon-calendar"></i> <%= $date %> 
        <i class="icon-user"></i> <%= $author %> 
        <i class="icon-folder-open"></i> <a href="<%= url_for("/category/$category") %>"><%= $category %></a> 
        <i class="icon-tag"></i> 
        % for my $tag ( @{$meta->tags} ) { 
            <a href="<%= url_for("/tags/$tag") %>"><%= $tag %></a>
        % }
        <span class="pull-right">
        <i class="icon-comment"></i><a href="<%= url_for($article_url) %>#disqus_thread">Link</a></span>
     </div>
     
     <%== $content %>
     <hr/>
     <div id="disqus_thread"></div>
  </div>
  

@@ layouts/default.html.ep
<!DOCTYPE html>
<html lang="en">
<head>
  <meta http-equiv="content-type" content="text/html; charset=UTF-8" />
  <!-- Title -->
  <title><%= title %></title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <!-- Description, Keywords -->
  <meta name="description" content="">
  <meta name="keywords" content="">
  <meta name="author" content="">
  
  <!-- Google web fonts -->
  <link href='http://fonts.googleapis.com/css?family=Oswald:400,700' rel='stylesheet' type='text/css'>
  <link href='http://fonts.googleapis.com/css?family=PT+Sans:400,700,400italic' rel='stylesheet' type='text/css'>

  <!-- Stylesheets -->
  <link href="/style/bootstrap.css" rel="stylesheet">
  <link href="/style/flexslider.css" rel="stylesheet">
  <link href="/style/prettyPhoto.css" rel="stylesheet">
  <link rel="stylesheet" href="/style/font-awesome.css">
  <!--[if IE 7]>
  <link rel="stylesheet" href="/style/font-awesome-ie7.css">
  <![endif]-->		
  <link href="/style/style.css" rel="stylesheet">
<!-- Color Stylesheet - orange, blue, pink, brown, red or green-->
  <link href="/style/blue.css" rel="stylesheet">      
  <link href="/style/bootstrap-responsive.css" rel="stylesheet">
  
  <!-- HTML5 Support for IE -->
  <!--[if lt IE 9]>
  <script src="/js/html5shim.js"></script>
  <![endif]-->

  <!-- syntaxhighlight -->
  <link rel="stylesheet" type="text/css" href="/syntaxhighlight/styles/shCore.css" />
  <link rel="stylesheet" type="text/css" href="/syntaxhighlight/styles/shThemeDjango.css" />
  <link rel="stylesheet" type="text/css" href="/syntaxhighlight/styles/lineshift-patch.css" />
  <link rel="stylesheet" type="text/css" href="/syntaxhighlight/styles/custom.css" />

  <!-- Favicon -->
  <link rel="shortcut icon" href="/img/favicon/skyloader-blog-favicon.png">
</head>

<body>

<!-- Header starts -->

<header>
   <div class="container">
      <div class="row">
         <div class="span4">
            <!-- Logo and site link -->
            <div class="logo">
               <h1><a href="/"><%= $headline %><span class="color">::</span></a><%= $subheadline %></h1>
            </div>
         </div>
      </div>
   </div>
</header>

<!-- Header ends -->

<!-- Navigation Starts -->

   <div class="navbar">
      <div class="navbar-inner">
        <div class="container">
          <a class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
            Menu
          </a>
          <div class="nav-collapse collapse">
            <!-- Navigation links starts here -->
            <ul class="nav">
              <!-- Main menu -->
              <li><a href="/recent">Blog</a></li>
              <li><a href="/archive">Archive</a></li>
              <!-- Navigation with sub menu. Please note down the syntax before you need. Each and every link is important. -->
            </ul>
          </div>
        </div>
      </div>
    </div>
    
<!-- Navigation Ends -->   

<!-- Content strats -->

<div class="content">
   <div class="container">
      <div class="row">
         <div class="span12">
            <!-- Blog starts -->
            
            <div class="blog">
               <div class="row">
                  <div class="span12">

                     <!-- Blog Posts -->
                     <div class="row">
                        <div class="span8">
                           <div class="posts">
                             <%= content %>
                           </div>
                        </div>                        
                        <div class="span4">
                           <div class="sidebar">
                              <!-- Widget -->
                              <div class="widget">
                                 <h4>Search</h4>
                                 <form method="get" id="searchform" action="http://google.com/search" class="form-search">
                                 <input type="hidden" value="site:localhost:3000" name="q">
                                 <input class="input-medium" type="text" placeholder="Search" results="0" name="q">
                                 <button type="submit" class="btn">Search</button>
                                 </form>
                              </div>
                              <div class="widget">
                                 <h4>Recent Posts</h4>
                                 <ul>
                                   % for my $item (@$recent_articles) {
                                     <li> <a href="<%= url_for("/page/$item->{meta_id}") %>"><%= $item->{article}->meta->title %></a></li>
                                   % }
                                 </ul>
                              </div>
                              <div class="widget">
                                 <h4>About</h4>
                                 <p> <%== $about %> </p>
                              </div>                              
                           </div>                                                
                        </div>
                     </div>
                     
                     
                     
                  </div>
               </div>
            </div>
                     
                              
                           
         </div>
      </div>
   </div>
</div>   

<!-- Content ends --> 
	
<!-- Footer -->
<footer>
  <div class="container">
    <div class="row">
      <div class="span4">
         <!-- Footer Widget 1-->
         <div class="widget">
            <h4>Twitter</h4>
               <a class="twitter-timeline"  href="https://twitter.com/viewrize"  data-widget-id="398054488788852736">Tweets by @viewrize</a>
               <script>!function(d,s,id){var js,fjs=d.getElementsByTagName(s)[0],p=/^http:/.test(d.location)?'http':'https';if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.src=p+"://platform.twitter.com/widgets.js";fjs.parentNode.insertBefore(js,fjs);}}(document,"script","twitter-wjs");</script>

            <!-- Too add twitter widget, goto "js" folder and open "custom.js" file and search for the word "ashokramesh90". This is my twitter username. Just replace the word with your twitter username. You are done. -->
            <!-- <div class="tweet"></div> -->
         </div>
      </div>
      <div class="span4">
         <!-- Footer Widget 2-->
         <div class="widget">
            <h4>Recent Posts</h4>
               <ul>
                 % for my $item (@$recent_articles) {
                      <li> <a href="<%= url_for("/page/$item->{meta_id}") %>"><%= $item->{article}->meta->title %></a></li>
                 % }
               </ul>
         </div>
      </div>
      <div class="span4">
         <!-- Footer Widget 3-->
         <div class="widget">
            <h4>Categories</h4>
            <ul>
              % for my $category (@$categories) {
                  <li> <a href="<%= url_for("/category/$category") %>"><%= $category %></a></li>
              % }
            </ul>
         </div>
      </div>
      
      <div class="span12"><hr /><p class="copy">
         <!-- Copyright information. You can remove my site link. -->
               Copyright &copy; <a href="#">Skyloader.org</a> </p></div>
    </div>
  </div>
</footer>		

<!-- JS -->
<script src="/js/jquery.js"></script>
<script src="/js/bootstrap.js"></script>
<script src="/js/jquery.flexslider-min.js"></script>
<script src="/js/jquery.isotope.js"></script>
<script src="/js/jquery.prettyPhoto.js"></script>
<script src="/js/filter.js"></script>
<script src="/js/jquery.tweet.js"></script>
<!-- <script src="/js/custom.js"></script> -->
<!-- <script src="/js/markdown-editor.js"></script> -->
<script type="text/javascript" src="/syntaxhighlight/scripts/shCore.js"></script>
<script type="text/javascript" src="/syntaxhighlight/scripts/shBrushAS3.js        "></script>
<script type="text/javascript" src="/syntaxhighlight/scripts/shBrushAppleScript.js"></script>
<script type="text/javascript" src="/syntaxhighlight/scripts/shBrushBash.js       "></script>
<script type="text/javascript" src="/syntaxhighlight/scripts/shBrushCSharp.js     "></script>
<script type="text/javascript" src="/syntaxhighlight/scripts/shBrushColdFusion.js "></script>
<script type="text/javascript" src="/syntaxhighlight/scripts/shBrushCpp.js        "></script>
<script type="text/javascript" src="/syntaxhighlight/scripts/shBrushCss.js        "></script>
<script type="text/javascript" src="/syntaxhighlight/scripts/shBrushDelphi.js     "></script>
<script type="text/javascript" src="/syntaxhighlight/scripts/shBrushDiff.js       "></script>
<script type="text/javascript" src="/syntaxhighlight/scripts/shBrushErlang.js     "></script>
<script type="text/javascript" src="/syntaxhighlight/scripts/shBrushGroovy.js     "></script>
<script type="text/javascript" src="/syntaxhighlight/scripts/shBrushJScript.js    "></script>
<script type="text/javascript" src="/syntaxhighlight/scripts/shBrushJava.js       "></script>
<script type="text/javascript" src="/syntaxhighlight/scripts/shBrushJavaFX.js     "></script>
<script type="text/javascript" src="/syntaxhighlight/scripts/shBrushPerl.js       "></script>
<script type="text/javascript" src="/syntaxhighlight/scripts/shBrushPhp.js        "></script>
<script type="text/javascript" src="/syntaxhighlight/scripts/shBrushPlain.js      "></script>
<script type="text/javascript" src="/syntaxhighlight/scripts/shBrushPowerShell.js "></script>
<script type="text/javascript" src="/syntaxhighlight/scripts/shBrushPython.js     "></script>
<script type="text/javascript" src="/syntaxhighlight/scripts/shBrushRuby.js       "></script>
<script type="text/javascript" src="/syntaxhighlight/scripts/shBrushSass.js       "></script>
<script type="text/javascript" src="/syntaxhighlight/scripts/shBrushScala.js      "></script>
<script type="text/javascript" src="/syntaxhighlight/scripts/shBrushSql.js        "></script>
<script type="text/javascript" src="/syntaxhighlight/scripts/shBrushVb.js         "></script>
<script type="text/javascript" src="/syntaxhighlight/scripts/shBrushXml.js        "></script>
<script type="text/javascript">
    $(document).ready(function() {
        SyntaxHighlighter.all()
    });
</script>
<script type="text/javascript">
    /* * * CONFIGURATION VARIABLES: EDIT BEFORE PASTING INTO YOUR WEBPAGE * * */
    var disqus_shortname = 'skyloader'; // required: replace example with your forum shortname

    /* * * DON'T EDIT BELOW THIS LINE * * */
    (function() {
        var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;
        dsq.src = '//' + disqus_shortname + '.disqus.com/embed.js';
        (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
    })();
</script>
<noscript>Please enable JavaScript to view the <a href="http://disqus.com/?ref_noscript">comments powered by Disqus.</a></noscript>
<a href="http://disqus.com" class="dsq-brlink">comments powered by <span class="logo-disqus">Disqus</span></a>

<script type="text/javascript">
/* * * CONFIGURATION VARIABLES: EDIT BEFORE PASTING INTO YOUR WEBPAGE * * */
var disqus_shortname = 'skyloader'; // required: replace example with your forum shortname

/* * * DON'T EDIT BELOW THIS LINE * * */
(function () {
    var s = document.createElement('script'); s.async = true;
    s.type = 'text/javascript';
    s.src = '//' + disqus_shortname + '.disqus.com/count.js';
    (document.getElementsByTagName('HEAD')[0] || document.getElementsByTagName('BODY')[0]).appendChild(s);
}());
</script>
</body>
</html>


@@ not_found.html.ep
% layout 'default',
%   recent_articles => [ get_recent_articles(10) ],
%   categories      => [ get_categories() ],
%   ;
% title '404 Not Found';
<!-- 404 starts -->
<div class="error">
   <div class="row">
      <div class="span8">
         <div class="error-page">
            <p class="error-med">Oops! Something missing</p>                        
            <p class="error-big">404<span class="color">!!!</span></p>                        
            <p class="error-small">Fusce imperdiet, risus eget viverra faucibus, diam mi vestibulum libero, ut vestibulum tellus magna nec enim. Nunc dapibus varius interdum.</p>
         </div>
      </div>
   </div>
</div>
<!-- 404 ends -->


