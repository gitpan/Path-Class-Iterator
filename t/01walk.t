use Test::More tests => 2;

use strict;
use warnings;

use Path::Class::Iterator;

my $root = '.';

ok(my $walker = Path::Class::Iterator->new(root => $root), "new object");

my $count = 0;
while (my $f = $walker->next)
{
    $count++;
    if (-l $f)
    {
        #diag "$f is a symlink";
    }
    elsif (-d $f)
    {
        #diag "$f is a dir";
    }
    elsif (-f $f)
    {
        #diag "$f is a file";
    }
    else
    {
        #diag "no idea what $f is";
    }

    last if $walker->done;
}

ok($count > 1, "found some files");
