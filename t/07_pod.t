# 07/pod.t
#
# test suite for Regexp::Assemble
# Make sure the pod is correct

use Test::More tests => 2;

my $have_Test_Pod = do {
    eval { require Test::Pod; import Test::Pod };
    $@ ? 0 : 1;
};

SKIP: {
    skip 'Test::Pod not installed on this system', 2
        unless $have_Test_Pod;

pod_file_ok( 'Assemble.pm' );
pod_file_ok( 'eg/assemble' );

}
