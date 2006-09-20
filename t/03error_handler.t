use Test::More;

use Path::Class::Iterator;

my %links = (
             'cannot_chdir' => 'test/link_to_cannot_chdir',
             'foo'          => 'test/bar',
             '/no/such/dir' => 'test/no_such_dir'
            );

mkdir('test/cannot_chdir', 0000);

# catch fatal errs for systems that don't have symlinks
my $no_links = 0;
for my $real (keys %links)
{
    unless (eval { symlink $real, $links{$real}; 1; })
    {
        $no_links = 1;
    }
}

if ($no_links)
{
    plan tests => 2;
}
else
{
    plan tests => 3;
}

my $root    = 'test';
my $skipped = 0;

sub debug
{
    diag(@_) if $ENV{PERL_TEST};
}

ok(
    my $walker = Path::Class::Iterator->new(
        root          => $root,
        error_handler => sub {
            my ($self, $path, $msg) = @_;

            debug $self->error;
            debug "we'll skip $path";
            $skipped++;

            return 1;
        },
        follow_symlinks => 1,
        breadth_first   => 1
                                           ),
    "new object"
  );

my $count = 0;
until ($walker->done)
{
    my $f = $walker->next;

    $count++;
    if (-l $f)
    {
        debug "$f is a symlink";
    }
    elsif (-d $f)
    {
        debug "$f is a dir";
    }
    elsif (-f $f)
    {
        debug "$f is a file";
    }
    else
    {
        debug "no idea what $f is";
    }

}

ok($count > 1, "found some files");
debug "skipped $skipped files";
unless ($no_links)
{
    cmp_ok($skipped, '==', 2, "skipped bad links");
}
