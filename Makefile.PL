use ExtUtils::MakeMaker;
eval "use ExtUtils::MakeMaker::Coverage";

print "Adding testcover target\n" unless $@;

WriteMakefile(
    'NAME'	       => 'Regexp::Assemble',
    'VERSION_FROM' => 'Assemble.pm',
    'PREREQ_PM' => {
		'Test::Simple' => 0,
		'Test::More'   => 0,
	},
);
