use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	       => 'Regexp::Assemble',
    'VERSION_FROM' => 'Assemble.pm',
    'PREREQ_PM' => {
		'Test::Simple' => 0,
		'Test::More'   => 0,
	},
);
