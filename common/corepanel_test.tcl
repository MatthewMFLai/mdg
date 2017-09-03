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

if {$tcl_platform(platform) == "windows"} {
    source ../common/corepanel.tcl
} else {
    source $env(COREPANEL_HOME)/corepanel.tcl
}

proc create_linkage {} {
    set modulelist [CorePanel::Get_Modules]
    foreach p_from_module $modulelist {
	foreach p_to_module $modulelist {
	    if {$p_from_module != $p_to_module} {
    		#puts "From: [bySymbol::get_symbol $p_from_module] To: [bySymbol::get_symbol $p_to_module]"
		CorePanel::Set_Linkage $p_from_module $p_to_module
	    }
	}
    }
}
	

proc create_symbols {symbolfile filterlist} {

    set is_ok 0
    if {$filterlist == ""} {
	set is_ok 1
    }
    set fd [open $symbolfile r]
    while {[gets $fd line] > -1} {
	set symbol [lindex $line 1]
    	switch -- [lindex $line 0] \
	  MODULE {
	    if {[lsearch $filterlist $symbol] != -1 || $is_ok} {
    	    	set p_module [CorePanel::Create_Module $symbol]
		set ok 1
	    } else {
		set ok 0
	    }
   	} t {
	    if {$ok} {
	    CorePanel::Create_Symbol $symbol $p_module LOCAL 1 0 
	    }
   	} T {
	    if {$ok} {
	    CorePanel::Create_Symbol $symbol $p_module GLOBAL 1 0 
	    }

   	} b {
	    if {$ok} {
	    CorePanel::Create_Symbol $symbol $p_module LOCAL 0 0 
	    }

   	} B {
	    if {$ok} {
	    CorePanel::Create_Symbol $symbol $p_module GLOBAL 0 0 
	    }

   	} c {
	    if {$ok} {
	    CorePanel::Create_Symbol $symbol $p_module LOCAL 0 1 
	    }

   	} C {
	    if {$ok} {
	    CorePanel::Create_Symbol $symbol $p_module GLOBAL 0 1 
	    }

   	} d {
	    if {$ok} {
	    CorePanel::Create_Symbol $symbol $p_module LOCAL 0 0 
	    }

   	} D {
	    if {$ok} {
	    CorePanel::Create_Symbol $symbol $p_module GLOBAL 0 0 
	    }

   	} U {
	    if {$ok} {
	    CorePanel::Create_Symbol $symbol $p_module REQUIRED 0 0 
	    }

   	} r {
	    if {$ok} {
	    CorePanel::Create_Symbol $symbol $p_module LOCAL 0 0 
	    }

   	} R {
	    if {$ok} {
	    CorePanel::Create_Symbol $symbol $p_module GLOBAL 0 0 
	    }

   	} s {
	    if {$ok} {
	    CorePanel::Create_Symbol $symbol $p_module LOCAL 0 0 
	    }

   	} S {
	    if {$ok} {
	    CorePanel::Create_Symbol $symbol $p_module GLOBAL 0 0 
	    }


   	} default { 
	    puts "line $line not processed."
   	}

    }
    close $fd

    return
}
 
CorePanel::Init_Corepanel

set symbolfile [lindex $argv 0]
set filterfile [lindex $argv 1]

set filterlist ""
if {[file exists $filterfile] && $filterfile != ""} {
    set fd [open $filterfile r]
    while {[gets $fd line] > -1} {
	if {[string first "#" $line] == 0} {
	    continue
	}
	lappend filterlist $line
    }
    puts "filterlist = $filterlist"
    close $fd
}
create_symbols $symbolfile $filterlist

create_linkage

CorePanel::Dump

CorePanel::Save_Corepanel corepanel.dat

CorePanel::Dump_Linkage

set loopfilterlist ""
set linkcolorlist ""
CorePanel::Check_Loop loopfilterlist linkcolorlist

CorePanel::Check_Unresolved_Globals

CorePanel::Dot_Output $loopfilterlist $linkcolorlist 0

exit 0
