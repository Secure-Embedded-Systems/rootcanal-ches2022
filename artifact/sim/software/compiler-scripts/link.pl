#!/usr/bin/perl -w
use File::Spec;
#==========================================================================
# link.pl

#  Copyright (c) 2018 ASCS Laboratory (ASCS Lab/ECE/BU)
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.

#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#  THE SOFTWARE.
#


(our $usageMsg = <<'ENDMSG') =~ s/^\#/ /gm;
#
# This script appends RISC-V assembly code snippets to set up (1) the stack
# pointer and (2) program return value and stop signal. 
#
ENDMSG

use strict "vars";
use warnings;
no  warnings("once");
use Getopt::Long;

my $stack   = pop @ARGV;
my $target  = pop @ARGV;
my @sources = @ARGV;

die "Usage: $0 in in ... in  out\n" if not @sources;
 
open my $out, '>>', $target or die "Could not open '$target' for appending\n"; 
foreach my $file (@sources) {
    if (open my $in, '<', $file) {
        while (my $line = <$in>) {
            $line =~ s/\[x\]/$stack/g; 
            print $out $line;
        }
        close $in;
    } else {
        warn "Could not open '$file' for reading\n";
    }
}
close $out;
 

