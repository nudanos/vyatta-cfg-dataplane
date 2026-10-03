#!/usr/bin/perl
# On a system that forwards in the Linux kernel there is no controller:
# Vyatta::VPlaned stores succeed without sending. vyatta-intf-end stores the
# default "speed auto" for every dataplane interface, and waited for the
# controller for ever, hanging every commit of an interface address.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use lib 'lib';
use Vyatta::VPlaned;

my $dir = tempdir( CLEANUP => 1 );
$Vyatta::VPlaned::KERNEL_FORWARDING_MARKER = "$dir/kernel-forwarding";
open( my $fh, '>', $Vyatta::VPlaned::KERNEL_FORWARDING_MARKER ) or die;
close($fh);

{
    package FakePB;
    sub new    { bless {}, shift }
    sub encode { 'x' }
}

local $ENV{COMMIT_ACTION} = 'SET';
my $ctrl = Vyatta::VPlaned->new("ipc://$dir/no-controller.socket");
my $t0   = time;
my $r    = eval { $ctrl->store_pb( 'speed set dp0s3', FakePB->new, 'vyatta:speed', 'dp0s3' ) };
is( $@, '', 'store_pb does not die' );
ok( !$r, 'store_pb reports success' );
$r = eval { $ctrl->store( 'interfaces dataplane dp0s3 mtu', 'mtu set dp0s3 1500', 'dp0s3' ) };
is( $@, '', 'store does not die' );
ok( !$r, 'store reports success' );
ok( time - $t0 < 5, 'without waiting for a reply' );

done_testing();
