#!/usr/bin/perl
# On a system that forwards in the Linux kernel there is no DPDK dataplane and
# no controller to ask: Vyatta::Dataplane reports no dataplanes instead of
# waiting for the controller and dying ("no response from dataplane"), which
# failed every commit of the interfaces tree.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use lib 'lib';
use Vyatta::Dataplane;

my $dir = tempdir( CLEANUP => 1 );
$Vyatta::Dataplane::KERNEL_FORWARDING_MARKER = "$dir/kernel-forwarding";
open( my $fh, '>', $Vyatta::Dataplane::KERNEL_FORWARDING_MARKER ) or die;
close($fh);

no warnings 'redefine';
local *Vyatta::Dataplane::controller_command = sub { die "asked the controller\n" };

my ( $local, @ids ) = Vyatta::Dataplane::get_vplane_info();
is( $local,        0, 'no local dataplane' );
is( scalar(@ids),  0, 'no dataplanes' );

my ( $dpids, $dpconns ) = Vyatta::Dataplane::setup_fabric_conns();
is( scalar( @{$dpids} ), 0, 'no fabric connections' );
my $resp = vplane_exec_cmd( 'ifconfig -a', $dpids, $dpconns, 1 );
is( scalar( @{$resp} ), 0, 'commands get no responses, and do not die' );

done_testing();
