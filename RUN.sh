export PERL5LIB=lib:$PERL5LIB
export MOJO_CONFIG=frenchfry.conf
export MOJO_HOME=.
plenv exec morbo -l http://*:5000 --watch lib bin/frenchfry-web.pl
