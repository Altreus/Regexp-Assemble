# 07/pod.t
#
# test suite for Regexp::Assemble
# Make sure the pod is correct
#
# copyright (C) 2004-2005 David Landgren

eval qq{use Test::More tests => 3};
if( $@ ) {
    warn "# Test::More not available, no tests performed\n";
    print "1..1\nok 1\n";
    exit 0;
}

my $have_Test_Pod = do {
    eval { require Test::Pod; import Test::Pod };
    $@ ? 0 : 1;
};

SKIP: {
    skip( 'Test::Pod not installed on this system', 2 )
        unless $have_Test_Pod;

    pod_file_ok( 'Assemble.pm' );
    pod_file_ok( 'eg/assemble' );
}

my $have_Test_Pod_Coverage = do {
    eval { require Test::Pod::Coverage; import Test::Pod::Coverage };
    $@ ? 0 : 1;
};

SKIP: {
    skip( 'Test::Pod::Coverage not installed on this system', 1 )
        unless $have_Test_Pod_Coverage;
	pod_coverage_ok( "Regexp::Assemble", "POD coverage is go!" );
}
