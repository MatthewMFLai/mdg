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

set datafile [lindex $argv 0]
CorePanel::Load_Corepanel $datafile 
set groupfile [lindex $argv 1]
set nopdf [lindex $argv 5]

set colourlist "aquamarine4 red blue brown orangered darkgreen darkviolet indigo magenta turquoise4 goldenrod4"

array set symbollist {}
array set include_symbollist {}
set fd [open $groupfile r]
while {[gets $fd filename] > -1} {
    set line [string trim $filename]
    if {[string first "#" $filename] == 0} {
	continue
    }
    set symbollist($filename) ""
    array set symboldata {}
    CorePanel::Get_Symbol_Summary $filename symboldata
    foreach symbol [array names symboldata] {
	if {[lindex $symboldata($symbol) 0] == "REQUIRED"} {
	    continue
	}
	lappend symbollist($filename) $symbol
    }
    unset symboldata
}

set groupfilelist [array names symbollist]
foreach filename $groupfilelist {
    set include_symbollist($filename) ""
}

set dotdir [lindex $argv 2]
set outfile [lindex $argv 3]
set nobox [lindex $argv 4]
set dotsuffix ".dot"
set pdfsuffix ".pdf"

set fd2 [open $outfile$dotsuffix w]
puts $fd2 "digraph G \{"
puts $fd2 "ranksep=\"3.0 equally\"\;"
puts $fd2 "ratio=auto\;"
puts $fd2 "node \[shape=plaintext\]\;"
puts $fd2 ""
foreach filename $groupfilelist {
    # Read in the dot file for that module.
    set fd [open $dotdir/$filename$dotsuffix r]
    while {[gets $fd line] > -1} {
	if {[string first "->" $line] == -1} {
	    continue
	}
	# Extract the "to" symbol and check to make sure it is in the symbollist.
	set idx2 [string first "\[" $line]
	if {$idx2 == -1} {
	    set idx2 [string first ";" $line]
	}
	incr idx2 -1
	set idx $idx2
	while {1} {
	    if {[string index $line $idx] == " "} {
	        incr idx
    		break
	    }
	    incr idx -1
	}
	set tosymbol [string range $line $idx $idx2]

	# Extract the "from" symbol.
	set idx [string first "->" $line]
	incr idx -1
	while {1} {
	    if {[string index $line $idx] != " "} {
    		break
	    }
	    incr idx -1
	}
	set fromsymbol [string range $line 0 $idx]

	if {[string first "color=red" $line] == -1} {

	    # Use medium grey colour for the link.
	    if {[string first "style=" $line] == -1} {
		regsub ";" $line {[color=gray51];} line
	    } else {
	 	regsub {\]} $line {,color=gray51]} line
	    }

	    puts $fd2 $line
	    if {[lsearch $include_symbollist($filename) $fromsymbol] == -1} {
		lappend include_symbollist($filename) $fromsymbol
	    }
	    if {[lsearch $include_symbollist($filename) $tosymbol] == -1} {
		lappend include_symbollist($filename) $tosymbol
	    }
    	    continue
	}

	set found_symbol 0
	foreach modulename $groupfilelist {
	    if {[lsearch $symbollist($modulename) $tosymbol] > -1} {
		# No need for the red link since
		# - for boxed display, all procedures from the same module are grouped
		#   into a box already
		# - for no-boxed display, all procedure/data from the same modulo will
		#   have the same colour label.
		regsub "color=red" $line "color=gray51" line
	        puts $fd2 $line
		set found_symbol 1

	    	if {[lsearch $include_symbollist($modulename) $tosymbol] == -1} {
		    lappend include_symbollist($modulename) $tosymbol
	    	}

    		break
	    }
	}
	if {$found_symbol} {
	    if {[lsearch $include_symbollist($filename) $fromsymbol] == -1} {
		lappend include_symbollist($filename) $fromsymbol
	    }
	}
    }
    close $fd
    puts $fd2 ""
}

# Now put in the cluster definition into the dot file.
if {$nobox == 0} {
    foreach modulename $groupfilelist {
    	set line ""
    	append line "subgraph \"cluster_$modulename.c\" \{ label=\"$modulename.c\"; "
    	foreach symbol $symbollist($modulename) {
	    if {[lsearch $include_symbollist($modulename) $symbol] != -1} {
	    	append line "$symbol; "
	    }
    	}
    	append line "\}"    
    	puts $fd2 $line
    	puts $fd2 ""
    }

} else {
    
    set colouridx 0
    foreach modulename $groupfilelist {
	set colour [lindex $colourlist $colouridx]
    	# Add the module name to each symbol name like this
    	# <symbol name> [label="<module name>\n<symbol name>",color=<colour>]
    	foreach symbol $symbollist($modulename) {
	    if {[lsearch $include_symbollist($modulename) $symbol] != -1} {
	    	puts $fd2 "$symbol \[label=\"$modulename\\n$symbol\",fontcolor=$colour\]\;"
	    }
    	}
	incr colouridx
	if {$colouridx == [llength $colourlist]} {
	    set colouridx 0
	}
    }

}
puts $fd2 "\}"
close $fd2
if {$nopdf == ""} {
    catch {exec dot -Tpdf $outfile$dotsuffix -o $outfile$pdfsuffix} rc
}
exit 0
