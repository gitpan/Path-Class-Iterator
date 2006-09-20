use 5.008007;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Path::Class::Iterator',
    VERSION_FROM      => 'lib/Path/Class/Iterator.pm', # finds $VERSION
    PREREQ_PM         => {

            Path::Class => 0.01,
            Iterator    => 0.01,
            Class::Accessor::Fast => 0.01

    }, # e.g., Module::Name => 1.1
);
