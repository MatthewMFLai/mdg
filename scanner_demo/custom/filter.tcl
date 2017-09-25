#!/bin/sh
# \
exec tclsh $0 $@

if {0} {
    This script removes the non-symbol lines from the symbol file generated by the
    nm-new utility.
    The following lines are accepted:
00000000 b ??WKeylowBattCount
00000000 b FOBSerialNumber
         U GVPartitionMax
000007f4 T findFob
00000000 R fobModeTable
00000000 W memcpy

    The filtering criteria is:
    - 2nd column must be one of t,T,b,B,U,r,R,w,W,d,D
    - if the third column is b/B and the leading characters
      are ??, then ?? will be removed from the symbol name
    - remove lines with __
}

if { [llength $argv] != 1 } {
    puts "Usage: filter_st symbolfile"
    puts "Example: filter_st.tcl symbols.dat"
    exit -1
}

set filename [lindex $argv 0]

set fd [open $filename r]
set fd2 [open $filename.filtered w]

set strmap {b 1 B 1 d 1 D 1 t 1 T 1 r 1 R 1 w 1 W 1}
while {[gets $fd line] > -1} {
    # We have some issue with some pattern like
    # ...">_1 or ...">_2
    # so ignore these lines for now.
    if {[string first "...\">_" $line] > 0} {
	continue
    }
    # Need to remove the braces like { and }
    regsub -all "{" $line "" line 
    regsub -all "}" $line "" line 
    regsub -all "<" $line "" line 
    regsub -all ">" $line "" line
    # Seems like there are {"} in the data line, so take it out too.
    regsub -all "\"" $line "" line

    set numoftokens [llength $line]
    if {$numoftokens == 2} {
	set line [string trim $line]
	set token0 [lindex $line 0]
	if {$token0 != "U" && $token0 != "MODULE"} {
	    continue
	}
	set token1 [lindex $line 1]
	if {[string first "__" $token1] == 0} {
	    continue
	}
    } else {
    	set token0 [lindex $line 0]
    	set token1 [lindex $line 1]
    	set token2 [lindex $line 2]
	if {[string map $strmap $token1] != "1"} {
	    continue
	}
	if {[string first "\." $token2] == 0} {
	    continue
	}
	if {[string first "__" $token2] == 0} {
	    continue
	}
	if {[string first "?" $token2] == 0} {
	    continue
	}
	if {[string first "$" $token2] == 0} {
	    continue
	}

	set line "$token1 $token2" 
    }
    puts $fd2 $line
}
close $fd
close $fd2

exit 0