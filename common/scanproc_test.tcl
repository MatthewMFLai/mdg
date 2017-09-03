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

source corepanel.tcl
source scanproc.tcl

set datafile [lindex $argv 0]
CorePanel::Load_Corepanel $datafile 
set filename [lindex $argv 1]
set dirname $filename

set filelist [glob -directory $filename *.i]
foreach filenamepath $filelist {
    if {0} {
	if {$filename != "sys_buzzer.i"} {
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
    #Scanproc::Init [array names symboldata] [array names symboldata]
    Scanproc::Init $proclist $datalist
    Scanproc::Run $filenamepath
    Scanproc::Run_Data $filenamepath
    set dotsuffix ".dot"
    set pdfsuffix ".pdf"
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
	    if {[string first $symbol $procbody] != -1} {
		# Make sure the symbol is not matched to a substring.
		set idx [string first $symbol $procbody]
		incr idx -1 
		if {[string is alnum [string index $procbody $idx]] ||
                    [string index $procbody $idx] == "-" ||
                    [string index $procbody $idx] == "_"} {
		    continue
		}
		set idx [string first $symbol $procbody]
		incr idx [string length $symbol]
		if {[string is alnum [string index $procbody $idx]] ||
                    [string index $procbody $idx] == "-" ||
                    [string index $procbody $idx] == "_"} {
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
	    }
        }
	if {$standalone} {
	    puts $fd "$procname\;"
	}
    }
    puts $fd "\}"
    close $fd
    if {[catch {exec dot -Tpdf $filename$dotsuffix -o $filename$pdfsuffix} rc]} {
	puts "$rc"
	set dumpsuffix ".scandump"
	Scanproc::Dump $filename$dumpsuffix
    } else {
	if {[string first "_st" $dirname] == -1} {
    	    file copy -force $filename$dotsuffix graphviz/
    	    file copy -force $filename$pdfsuffix graphviz/
	} else {
    	    file copy -force $filename$dotsuffix graphviz_st/
    	    file copy -force $filename$pdfsuffix graphviz_st/
	}
    	file delete -force $filename$dotsuffix
    	file delete -force $filename$pdfsuffix
    }
    Scanproc::Clear
    unset symboldata
}
exit 0
