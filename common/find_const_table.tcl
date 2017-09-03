# Copyright (c) 2011, Matthew Lai <mmlai@sympatico.ca> 
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

#!/bin/sh
# \
exec tclsh $0 $@

set filedir [lindex $argv 1]
set filelist [glob -directory $filedir *.i]
array set const_table {}

foreach filename $filelist {
    set fd [open $filename r]
    set modulename [lindex [split $filename "."] 0]
    set modulename [lindex [split $modulename "/"] end]
    set const_table($modulename) ""

    while {[gets $fd line] > -1} {
	# Search for line that looks like
	# ... const ... abc[...] = ...
        if {[string match {*const *\[*\]*=*} $line]} {
	    lappend const_table($modulename) $line
        }
    }
    close $fd
}

set symbolfilename [lindex $argv 0]
set fd [open $symbolfilename r]
set fd2 [open $symbolfilename.tmp w]
while {[gets $fd line] > -1} {
    if {[lindex $line 0] == "MODULE"} {
	set modulename [lindex $line 1]
	puts $fd2 $line
	continue
    }
    if {[lindex $line 0] != "T" && [lindex $line 0] != "t"} {
	puts $fd2 $line
	continue
    }
    set symbol [lindex $line 1]
    if {[info exists const_table($modulename)] == 0} {
	puts $fd2 $line
	continue
    }
    set tmpidx [lsearch $const_table($modulename) "*$symbol*"]
    if {$tmpidx == -1} {
	puts $fd2 $line
    } else {
	# The line may be "... foo_1[...] ... and the symbol is foo.
	# We need to make sure we don't match foo with foo_1[...].
	set data [lindex $const_table($modulename) $tmpidx]
	set idx [string first $symbol $data]
	incr idx [string length $symbol]
	if {[string index $data $idx] != "\["} {
	    puts $fd2 $line
	    continue
	}

	if {[string is lower [lindex $line 0]]} {
	    puts $fd2 "b $symbol"
	} else {
	    puts $fd2 "B $symbol"
	}
    }
}
close $fd
close $fd2

file delete $symbolfilename
file rename $symbolfilename.tmp $symbolfilename

exit 0
