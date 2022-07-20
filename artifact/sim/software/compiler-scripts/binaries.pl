#!/usr/bin/perl -w
use File::Spec;
#==========================================================================
# binaries.pl

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
# This script seperates the instruction binary from the data and puts them into
# two seperate files named int_filename and data_filename.
#
ENDMSG


my$filename=shift(@ARGV);
my$instfile="inst_$filename";
my$datafile="data_$filename";

my$step   = 0; 

open(FILE, $filename) or die "Could not read from $filename, program halting.";

open(OUT,'>',$instfile) or die "Could not read from $instfile, program halting.";

while(<FILE>)
{
  # get rid of the pesky newline character
  chomp;

  @fields = split(':', $_);
  @chars  = split("", $fields[0]);
  
  if ($chars[0] eq '@'){
    if($step == 0) {$step = 1;}
    else {$step = 2;}
  }
  
  if($step == 1){
    print OUT "",$_,"\n";
  }
  else {
    if ($step == 2){ 
        close OUT;
        open(OUT,'>',$datafile) or die "Could not read from $datafile, program halting.";
        $step = 3;
    }
    print OUT "",$_,"\n";
  }
}
close FILE;
close OUT;
