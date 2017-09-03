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

source ../common/corepanel.tcl
source ../common/scanproc.tcl

set datafile [lindex $argv 0]
CorePanel::Load_Corepanel $datafile 
set filename [lindex $argv 1]
set dirname $filename
set simplify [lindex $argv 2]

set filelist [glob -directory $filename *.i]
foreach filenamepath $filelist {
    if {0} {
	if {[string first "raweventBuffer.i" $filenamepath] == -1} {
	    continue
	}
    }

    set tokens [split $filenamepath "/"]
    set filename [lindex $tokens end]
    puts "Processing $filename..."
    array set symboldata {}
    CorePanel::Get_Symbol_Summary [lindex [split $filename "."] 0] symboldata
    set symbollist [array names symboldata]
    if {$symbollist == ""} {
	puts "$filename contains no symbols. Skip."
    	unset symboldata
	continue
    }
    # Prepare a GLOBAL/LOCAL procedure/data lists.
    set proclist ""
    set datalist ""
    foreach symbol [array names symboldata] {
	if {[lindex $symboldata($symbol) 0] == "REQUIRED"} {
	    continue
	}
	if {[lindex $symboldata($symbol) 1]} {
	    lappend proclist $symbol
	} else {
	    lappend datalist $symbol
	} 
    }
    if {$simplify == "s" || $simplify == "S"} {
    	set symbollist [concat $proclist $datalist]
    }

    #Scanproc::Init [array names symboldata] [array names symboldata]
    Scanproc::Init $proclist $datalist
    Scanproc::Run $filenamepath
    Scanproc::Run_Data $filenamepath
    #Scanproc::Dump scanproc.dump
    if {$simplify == "s" || $simplify == "S"} {
    	set dotsuffix ".sim.dot"
    	set pdfsuffix ".sim.pdf"
    } else {
    	set dotsuffix ".dot"
    	set pdfsuffix ".pdf"
    }
    #set procsuffix ".proc"

    set filename [lindex [split $filename "."] 0]
    set fd [open $filename$dotsuffix w]
    puts $fd "digraph G \{"
    puts $fd "ranksep=\"3.0 equally\"\;"
    puts $fd "ratio=auto\;"
    puts $fd "node \[shape=plaintext\]\;"
    set proclist [Scanproc::Get_Iter]
    foreach procname $proclist {
        set procbody [Scanproc::Get_Proc $procname]
	set standalone 1
        foreach symbol $symbollist {
	    set from_idx 0
	    while {[string first $symbol $procbody $from_idx] != -1} {
		# Make sure the symbol is not matched to a substring.
		set idx [string first $symbol $procbody $from_idx]
		# We want to avoid the case where we match "foo"
		# with void abc_foo(...) or abcfoo(...)
		set idx2 [expr $idx - 1]
		set pre_char [string index $procbody $idx2]
		if {[string is alnum $pre_char] ||
		    $pre_char == "-" || $pre_char == "_" || $pre_char == "\."} {
		    set from_idx [expr [string length $symbol] + $from_idx]	    
		    continue 
		}
		set idx [string first $symbol $procbody $from_idx]
		incr idx [string length $symbol]
		set post_char [string index $procbody $idx]
		if {[string is alnum $post_char] ||
		    $post_char == "-" || $post_char == "_"} {	
		    set from_idx $idx
		    continue
		}
		set standalone 0
	        set is_function [lindex $symboldata($symbol) 1]
	        if {[lindex $symboldata($symbol) 0] == "REQUIRED"} {
		    if {$is_function} {
	    	        puts $fd "$procname -> $symbol\[color=red\]\;"
	    	    } else {
	    	        puts $fd "$procname -> $symbol\[color=red,style=dotted\]\;"
		    }
	        } else {
		    if {$is_function} {
	    	        puts $fd "$procname -> $symbol\;"
	    	    } else {
	    	        puts $fd "$procname -> $symbol\[style=dotted\]\;"
		    }
	        }
		# Set up dependency data between symbols.
		CorePanel::Set_Symbol_Depend $filename $procname \
                           [lindex $symboldata($procname) 0] \
                           $symbol \
                           [lindex $symboldata($symbol) 0]

		# Leave while loop
		break
	    } 
        }
	if {$standalone} {
	    puts $fd "$procname\;"
	}
    }
    # Find data --> procedure (function pointers) dependency
    set proclist [Scanproc::Get_Data_Iter]
    foreach procname $proclist {
        set procbody [Scanproc::Get_Data $procname]
	set standalone 1 
        foreach symbol $symbollist {
	    if {[string first $symbol $procbody] != -1} {
		# Make sure the symbol is not matched to a substring.
		set idx [string first $symbol $procbody]
		# We want to avoid the case where we match "foo"
		# with void abc_foo(...) or abcfoo(...)
		set idx2 [expr $idx - 1]
		set pre_char [string index $procbody $idx2]
		if {[string is alnum $pre_char] ||
		    $pre_char == "-" || $pre_char == "_"} {	
		    continue 
		}

		set idx [string first $symbol $procbody]
		incr idx [string length $symbol]
		if {[string is alnum [string index $procbody $idx]]} {
		    continue
		}
	        set standalone 0 
	        set is_function [lindex $symboldata($symbol) 1]
	        if {[lindex $symboldata($symbol) 0] == "REQUIRED"} {
		    if {$is_function} {
	    	        puts $fd "$procname -> $symbol\[color=red\]\;"
	    	    } else {
	    	        puts $fd "$procname -> $symbol\[color=red,style=dotted\]\;"
		    }
	        } else {
		    if {$is_function} {
	    	        puts $fd "$procname -> $symbol\;"
	    	    } else {
	    	        puts $fd "$procname -> $symbol\[style=dotted\]\;"
		    }
	        }
		# Set up dependency data between symbols.
		CorePanel::Set_Symbol_Depend $filename $procname \
                           [lindex $symboldata($procname) 0] \
                           $symbol \
                           [lindex $symboldata($symbol) 0]
	    }
        }
	if {$standalone} {
	    puts $fd "$procname\;"
	}
    }
    puts $fd "\}"
    close $fd
    if {[catch {exec dot -Tpdf $filename$dotsuffix -o $filename$pdfsuffix} rc]} {
	if {$tcl_platform(platform) != "windows"} {
	    set dumpsuffix ".scandump"
	    Scanproc::Dump $filename$dumpsuffix
	    puts "$rc"
	}
    	file delete -force $filename$dotsuffix
    } else {

	#set fd [open $filename$procsuffix w]
	#foreach procline [Scanproc::Get_Procline] {
	#    puts $fd $procline
	#}
	#close $fd

	if {[string first "_st" $dirname] == -1} {
    	    file copy -force $filename$dotsuffix graphviz/
    	    file copy -force $filename$pdfsuffix graphviz/
    	    #file copy -force $filename$procsuffix graphviz/
	} else {
    	    file copy -force $filename$dotsuffix graphviz_st/
    	    file copy -force $filename$pdfsuffix graphviz_st/
    	    #file copy -force $filename$procsuffix graphviz_st/
	}
    	file delete -force $filename$dotsuffix
    	file delete -force $filename$pdfsuffix
    	#file delete -force $filename$procsuffix
    }
    Scanproc::Clear
    unset symboldata
}
# Save symbol dependency data.
CorePanel::Dump_Symbol_Dependency
if {$tcl_platform(platform) != "windows"} {
    CorePanel::Save_Corepanel $datafile
} else {
    #file delete -force $datafile
}
exit 0
