#!/usr/bin/perl

# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use warnings;
use File::Find qw( find );
use FindBin;

-d "src" or die "Switch to the directory containg the charmonizer src/.\n";

my (@srcs, @tests, @hdrs);
my $license = "";

sub wanted {
    if (/\.c$/) {
        if (/^Test/) {
            push @tests, $File::Find::name;
        }
        else {
            push @srcs, $File::Find::name;
        }
    }
    elsif (/\.h$/) {
        push @hdrs, $File::Find::name;
    }
}

sub unixify {
    map { my $copy = $_; $copy =~ tr{\\}{/}; $copy } @_;
}

sub winnify {
    map { my $copy = $_; $copy =~ tr{/}{\\}; $copy } @_;
}

sub objectify {
    my @objects = @_;
    for (@objects) {
        s/\.c$/\$(OBJEXT)/ or die "No match: $_";
    }
    return @objects;
}

sub test_execs {
    my @test_execs = grep { $_ !~ /Test\.c/ } @_; # skip Test.c entry
    for (@test_execs) {
        s/.*(Test\w+)\.c$/$1\$(EXEEXT)/ or die "no match: $_";
    }
    return @test_execs;
}

sub test_blocks {
    my @c_files = grep { $_ !~ /Test\.c/ } @_; # skip Test.c entry
    my @blocks;
    for my $c_file (@c_files) {
        my $exe = $c_file; 
        $exe =~ s/.*(Test\w+)\.c$/$1\$(EXEEXT)/ or die "no match $exe";
        my $obj = $c_file;
        $obj =~ s/\.c$/\$(OBJEXT)/ or die "no match: $obj";
        push @blocks, <<END_BLOCK;
$exe: src/Charmonizer/Test\$(OBJEXT) $obj
\t\$(LINKER) \$(LINKFLAGS) src/Charmonizer/Test\$(OBJEXT) $obj \$(LINKOUT)"\$@"
END_BLOCK
    }
    return @blocks;
}

sub gen_makefile {
    my %args = @_;
    my $target = $args{target};
    die "Invalid target: $target" unless $target =~ /^(win|posix)$/;
    my ( $file, $clean );
    if ( $target eq 'win' ) {
        $file = 'base.win.mk';
        $clean = "CMD /c FOR %i IN (\$(CLEANABLE)) DO IF EXIST %i DEL /F %i\n";
    }
    else {
        $file = 'base.POSIX.mk';
        $clean = "rm -f \$(CLEANABLE)\n";
    }
    open my $fh, ">$file" or die "open '$file' failed: $!\n";
    my $content = <<EOT;
# GENERATED BY $FindBin::Script: do not hand-edit!!!
#
$license
PROGNAME= charmonize\$(EXEEXT)

TESTS= $args{test_execs}

OBJS= $args{objs}

TEST_OBJS= $args{test_objs}

HEADERS= $args{headers}

CLEANABLE= \$(OBJS) \$(PROGNAME) \$(TEST_OBJS) \$(TESTS) *.pdb

all: \$(PROGNAME)

\$(PROGNAME): \$(OBJS)
	\$(LINKER) \$(LINKFLAGS) \$(OBJS) \$(LINKOUT)"\$(PROGNAME)"

\$(OBJS) \$(TEST_OBJS): \$(HEADERS)

tests: \$(TESTS)

$args{test_blocks}
clean:
	$clean
EOT
    print $fh $content;
}

### actual script follows

open my $fh, $0 or die "Can't open $0: $!\n";
scalar <$fh>, scalar <$fh>; # skip first 2 lines
while (<$fh>) {
    /^#/ or last;
    $license .= $_;
}

push @srcs, "charmonize.c";
find \&wanted, "src";
@srcs  = sort @srcs;
@hdrs  = sort @hdrs;
@tests = sort @tests;
my @objects      = objectify(@srcs);
my @test_objects = objectify(@tests);
my @test_execs   = test_execs(@tests);
my @test_blocks  = test_blocks(@tests);

gen_makefile
    test_execs  => join(" ", unixify(@test_execs)),
    objs        => join(" ", unixify(@objects)),
    test_objs   => join(" ", unixify(@test_objects)),
    headers     => join(" ", unixify(@hdrs)),
    test_blocks => join("\n", unixify(@test_blocks)),
    target      => 'posix';

gen_makefile
    test_execs  => join(" ", winnify(@test_execs)),
    objs        => join(" ", winnify(@objects)),
    test_objs   => join(" ", winnify(@test_objects)),
    headers     => join(" ", winnify(@hdrs)),
    test_blocks => join("\n", winnify(@test_blocks)),
    target      => 'win';

__END__

=head1 NAME

gen_charmonizer_makefiles.pl

=head1 SYNOPSIS

    gen_charmonizer_makefiles.pl - keeps the Makefiles in sync with the live tree.

=head1 DESCRIPTION

Be sure to run this code from the charmonizer subdirectory (where the
existing Makefiles live).

