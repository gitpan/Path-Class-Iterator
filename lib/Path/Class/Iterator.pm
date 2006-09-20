package Path::Class::Iterator;

use strict;
use warnings;
use Path::Class;
use Carp;
use Iterator;

use base qw/ Class::Accessor::Fast /;

our $VERSION = '0.01';

sub _listing
{
    my $self = shift;
    my $path = shift;

    my $d = $path->open;

    Iterator::X::IO_Error(message => qq{Cannot read "$path": $!},
                          error   => $!)
      unless $d;

    return Iterator->new(
        sub {

            # Get next file, skipping . and ..
            my $next;
            while (1)
            {
                eval { $next = $d->read };

                if ($@)
                {
                    croak "error reading $next: $! ($@)";
                }

                if (!defined $next)
                {
                    undef $d;    # allow garbage collection
                    Iterator::is_done();
                }

                next if !$self->follow_hidden && $next =~ m/^\./o;

                last if $next ne '.' && $next ne '..';
            }

            # Return this item
            return -d dir($path, $next)
              ? dir($path, $next)
              : file($path, $next);
        }
    );
}

sub next
{
    my $self = shift;
    return $self->iterator->value;
}

sub done
{
    my $self = shift;
    return $self->iterator->is_exhausted;
}

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    my %opts  = @_;
    @$self{keys %opts} = values %opts;
    bless($self, $class);
    $self->mk_accessors(
                       qw/ root start follow_symlinks follow_hidden iterator /);

    $self->start(time());
    $self->root or croak "root param required";
    $self->root( dir($self->root) );
    my $files = $self->_listing($self->root);

    my @dir_queue;
    $self->iterator(
        Iterator->new(
            sub {

                # If no more files in current directory,
                # get next directory off the queue
                while ($files->is_exhausted)
                {

                    # Nothing else on the queue?  Then we're done.
                    if (@dir_queue == 0)
                    {
                        undef $files;    # allow garbage collection
                        Iterator::is_done();
                    }

                    # Create an iterator to return the files in that directory
                    $files = $self->_listing(shift @dir_queue);
                }

                # Get next file in current directory
                my $next = $files->value;

                # If this is a directory (and not a symlink), remember it for later recursion

                if (!$self->follow_symlinks)
                {
                    while (-l $next && $files->is_not_exhausted)
                    {
                        $next = $files->value;
                    }
                }

                if (-d $next)
                {

                    # depth vs breadth is unshift vs push ??
                    unshift(@dir_queue, $next);
                }

                return $next;
            }
        )
    );

    return $self;
}

1;

__END__

=pod

=head1 NAME

Path::Class::Iterator - walk a directory structure

=head1 SYNOPSIS

  use Path::Class::Iterator;
  
  my $dir = shift @ARGV || '';

  my $walker = Path::Class::Iterator->new(root => $dir);

  while (my $f = $walker->next)
  {
    # do something with $f
    # $f is a Path::Class::Dir or Path::Class::File object

    last if $walker->done;
  }

=head1 DESCRIPTION

Path::Class::Iterator walks a directory structure using an iterator.
It combines the L<Iterator> closure technique
with the magic of L<Path::Class>.

It is similar in idea to L<Iterator::IO> and L<IO::Dir::Recursive> 
but uses L<Path::Class> objects instead of L<IO::All> objects. 
It is also similar to the Path::Class
next() method, but automatically acts recursively. In fact, it is similar
to many recursive L<File::Find>-type modules, but not quite exactly like them.
If it were exactly like them, I wouldn't have written it. I think.

I cribbed much of the Iterator logic directly from L<Iterator::IO> and married
it with Path::Class. I'd been wanting to try something like Iterator::IO since
hearing MJD's HOP talk at OSCON 2006.

=head1 METHODS

=head2 new( %I<opts> )

Instantiate a new iterator object. %I<opts> may include:

=over

=item root

The root directory in which you want to start iterating. This
parameter is required.

=item follow_hidden

Files and directories starting with a dot B<.> are skipped by default.
Set this to true to include these hidden items in your iterations.

=item follow_symlinks

Symlinks (or whatever returns true with the built-in B<-l> flag on your system)
are skipped by default. Set this to true to follow symlinks.

=back

=head2 next

Returns the next file or directory from the P::C::I object.

=head2 start

Returns the start time in Epoch seconds that the P::C::I object was
first created.

=head2 done

Returns true if the P::C::I object has run out of items to iterate over.

=head2 iterator

Returns the internal Iterator object. You probably don't want that, but just in case.

=head2 root

Returns the B<root> param set in new().

=head2 follow_symlinks

Get/set the param set in new().

=head2 follow_hidden

Get/set the param set in new().


=head1 TODO

Breadth vs. depth option to new() for how to walk each directory.

=head1 SEE ALSO

I<Higher Order Perl>, Mark Jason Dominus, Morgan Kauffman 2005.

L<http://perl.plover.com/hop/>

L<Iterator>, L<Iterator::IO>, L<Path::Class>, L<IO::Dir::Recursive>, L<IO::Dir>


=head1 AUTHOR

Peter Karman, E<lt>karman@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
