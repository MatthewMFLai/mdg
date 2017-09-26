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

if {$tcl_platform(platform) == "windows"} {
source ../common/malloc.tcl
} else {
source $env(COREPANEL_HOME)/malloc.tcl
}
foreach filename [glob $env(MDG_HOME)/gencode/simple/*.tcl] {
    source $filename
}   
# DYNAMIC SOURCE END 
# DYNAMIC SOURCE BEGIN
foreach filename [glob $env(MDG_HOME)/gencode/complex/*.tcl] {
    source $filename
}
# DYNAMIC SOURCE END
# DYNAMIC SOURCE BEGIN
foreach filename [glob $env(MDG_HOME)/gencode/dynamic_type/*.tcl] {
    source $filename
}
# DYNAMIC SOURCE END

namespace eval CorePanel {

    variable g_corepanel

proc Init_Corepanel {} {

    variable g_corepanel
    variable g_version
    malloc::init

    # Initiailize the graph object first.
    set g_corepanel [malloc::getmem]
    init_Corepanel $g_corepanel

    set g_version "0.02"
}

proc Create_Module {name} {
    variable g_corepanel

    set p_thing [malloc::getmem]
    init_Module $p_thing
	bySymbol::set_symbol $p_thing $name
	byCorepanel_Module::set_key $p_thing $name
    byCorepanel_Module::add_part $g_corepanel $p_thing

    set p_thing2 [malloc::getmem]
    init_Property $p_thing2
	bySymbol::set_symbol $p_thing2 "GLOBAL"
	byModule_Property::set_key $p_thing2 "GLOBAL"
    byModule_Property::add_part $p_thing $p_thing2
    set p_thing2 [malloc::getmem]
    init_Property $p_thing2 "LOCAL"
	bySymbol::set_symbol $p_thing2 "LOCAL"
	byModule_Property::set_key $p_thing2 "LOCAL"
    byModule_Property::add_part $p_thing $p_thing2
    set p_thing2 [malloc::getmem]
    init_Property $p_thing2 "REQUIRED"
	bySymbol::set_symbol $p_thing2 "REQUIRED"
	byModule_Property::set_key $p_thing2 "REQUIRED"
    byModule_Property::add_part $p_thing $p_thing2

    return $p_thing
}

proc Create_Symbol {name p_module type is_function is_bss} {

    set p_thing [malloc::getmem]
    switch -- $type \
	REQUIRED {
	    init_Symbolrequired $p_thing
		bySymbol::set_symbol $p_thing $name
		bySym_Property::set_key $p_thing $name
		byRequired_Sym_Link::set_key $p_thing $name
		
    } GLOBAL {
	    init_Symbolglobal $p_thing
		bySymbol::set_key $p_thing $name
		bySym_Property::set_key $p_thing $name
		bySymbolDefined::set_is_function $p_thing $is_function
		bySymbolDefined::set_is_bss $p_thing $is_bss		
    } LOCAL { 
	    init_Symboldefined $p_thing
		bySymbol::set_symbol $p_thing $name
		bySym_Property::set_key $p_thing $name
		bySymbolDefined::set_is_function $p_thing $is_function
		bySymbolDefined::set_is_bss $p_thing $is_bss
    }

    set p_property [byModule_Property::get_part $p_module $type]
    bySym_Property::add_part $p_property $p_thing

    return
}

proc get_symbollist {p_module propertytype} {
    set symbollist ""
    set p_property [byModule_Property::get_part $p_module $propertytype]
    foreach p_symbol [bySym_Property::get_iterator $p_property] {
	lappend symbollist [bySymbol::get_symbol $p_symbol]
    }
    return $symbollist
}

proc get_p_symbollist {p_module propertytype} {
    set p_property [byModule_Property::get_part $p_module $propertytype]
    return [bySym_Property::get_iterator $p_property]
}

proc get_function_symbollist {p_module propertytype} {
    set symbollist ""
    set p_property [byModule_Property::get_part $p_module $propertytype]
    foreach p_symbol [bySym_Property::get_iterator $p_property] {
	if {[bySymbolDefined::get_is_function $p_symbol]} {
	    lappend symbollist [bySymbol::get_symbol $p_symbol]
	}
    }
    return $symbollist
}

proc get_data_p_symbollist {modulename propertytype} {
    variable g_corepanel

    set p_module [byCorepanel_Module::get_part $g_corepanel $modulename]
    set p_symbollist ""
    set p_property [byModule_Property::get_part $p_module $propertytype]
    foreach p_symbol [bySym_Property::get_iterator $p_property] {
	if {[bySymbolDefined::get_is_function $p_symbol] == 0} {
	    lappend p_symbollist $p_symbol
	}
    }
    return $p_symbollist
}

proc lintersect {a b} {
    foreach e $a {
	set x($e) {}
    }
    set result {}
    foreach e $b {
	if {[info exists x($e)]} {
 	    lappend result $e
 	}
    }
    return $result
}

proc ldifference {a b} {
     foreach e $b {
 	set x($e) {}
     }
     set result {}
     foreach e $a {
 	if {![info exists x($e)]} {
 	    lappend result $e
 	}
     }
     return $result
}

proc Check_Loop {p_returnlist p_linkcolorlist} {
    variable g_corepanel

    upvar $p_returnlist returnlist
    upvar $p_linkcolorlist linkcolorlist

    set returnlist ""
    set linkcolorlist ""

    set modulelist [byCorepanel_Module::get_iterator $g_corepanel]
    if {[llength $modulelist] < 2} {
	return
    }

    set fd [open corepanel_loop.dump w]

    set modulecountlist ""

    while {[llength $modulelist] > 1} {
    	set p_module [lindex $modulelist 0]
    	set modulelist [lrange $modulelist 1 end]
    	foreach p_other_module $modulelist {
    	    set required_list [get_symbollist $p_module REQUIRED] 
    	    set global_list [get_symbollist $p_other_module GLOBAL] 

    	    # Get the intersection of the two lists to see if there
    	    # is any linkage between the two modules.
    	    set resultlist1 [lintersect $required_list $global_list]

    	    set required_list [get_symbollist $p_other_module REQUIRED] 
    	    set global_list [get_symbollist $p_module GLOBAL] 

    	    # Get the intersection of the two lists to see if there
    	    # is any linkage between the two modules.
    	    set resultlist2 [lintersect $required_list $global_list]

	    if {$resultlist1 != "" && $resultlist2 != ""} {
		set length1 [llength [lintersect $resultlist1 \
                    [get_function_symbollist $p_other_module GLOBAL]]]
		set length2 [llength [lintersect $resultlist2 \
                    [get_function_symbollist $p_module GLOBAL]]]
		if {$length1 >= $length2} {
	    	    puts $fd "[bySymbol::get_symbol $p_other_module] [bySymbol::get_symbol $p_module]"
	    	    lappend returnlist "[bySymbol::get_symbol $p_other_module] [bySymbol::get_symbol $p_module]"
	    	    lappend linkcolorlist "[bySymbol::get_symbol $p_module] [bySymbol::get_symbol $p_other_module]"
		} else {
	    	    puts $fd "[bySymbol::get_symbol $p_module] [bySymbol::get_symbol $p_other_module]"
	    	    lappend returnlist "[bySymbol::get_symbol $p_module] [bySymbol::get_symbol $p_other_module]"
	    	    lappend linkcolorlist "[bySymbol::get_symbol $p_other_module] [bySymbol::get_symbol $p_module]"
		}
		lappend modulecountlist $p_module
		lappend modulecountlist $p_other_module
	    }
    	}
    }
    puts $fd "Number of modules with loop: [llength [lsort -unique $modulecountlist]]"
    close $fd
}

proc Set_Linkage {p_from_module p_to_module} {
    set required_list [get_symbollist $p_from_module REQUIRED] 
    set global_list [get_symbollist $p_to_module GLOBAL] 

    # Get the intersection of the two lists to see if there
    # is any linkage between the two modules.
    set resultlist [lintersect $required_list $global_list]
    if {$resultlist == ""} {
	return
    }

    #puts "From: [bySymbol::get_symbol $p_from_module]"
    #puts "To  : [bySymbol::get_symbol $p_to_module]"
    #puts "resultlist = $resultlist"

    # The to_module provides symbols used by the from_module.
    # Set the link between the two modules. 
    set p_link [malloc::getmem]
    init_Link $p_link
    byModule_Link::graph_add_edge $p_from_module $p_to_module $p_link

    # Add the required symbols to the link.
    foreach symbol $resultlist {
    	set p_property [byModule_Property::get_part $p_from_module REQUIRED]
    	set p_symbol [bySym_Property::get_part $p_property $symbol]
	byRequired_Sym_Link::add_part $p_link $p_symbol	
    }

    # Set up the lattice between the global symbols and the link.
    foreach symbol $resultlist {
    	set p_property [byModule_Property::get_part $p_to_module GLOBAL]
    	set p_symbol [bySym_Property::get_part $p_property $symbol]
	byGlobal_Sym_Link::add_rel $p_link $p_symbol	
    }
}

proc Set_Symbol_Depend {module fromsymbol fromproperty tosymbol toproperty} {
    variable g_corepanel

    set p_module [byCorepanel_Module::get_part $g_corepanel $module]
    if {$p_module == "NULL"} {
	return
    }
 
    set p_property [byModule_Property::get_part $p_module $fromproperty]
    if {$p_property == "NULL"} {
	return
    }
    set p_fromsymbol [bySym_Property::get_part $p_property $fromsymbol]
    if {$p_fromsymbol == "NULL"} {
	return
    }

    set p_property [byModule_Property::get_part $p_module $toproperty]
    if {$p_property == "NULL"} {
	return
    }
    set p_tosymbol [bySym_Property::get_part $p_property $tosymbol]
    if {$p_tosymbol == "NULL"} {
	return
    }

    if {[bySymbol_Depend::graph_get_edge $p_fromsymbol $p_tosymbol] != ""} {
	return
    }

    set p_depend [malloc::getmem]
    init_Depend $p_depend
    bySymbol_Depend::graph_add_edge $p_fromsymbol $p_tosymbol $p_depend
    #puts "$module: $fromproperty $fromsymbol ---> $toproperty $tosymbol"
}

proc Get_Modules {} {
    variable g_corepanel
    return [byCorepanel_Module::get_iterator $g_corepanel]
}

proc Get_Symbol_Summary {modulename p_symboldata} {
    variable g_corepanel

    upvar $p_symboldata symboldata

    set p_module [byCorepanel_Module::get_part $g_corepanel $modulename]
    if {$p_module == "NULL"} {
	return
    }
    foreach p_property [byModule_Property::get_iterator $p_module] {
    	set propertytype [bySymbol::get_symbol $p_property]
	foreach p_symbol [bySym_Property::get_iterator $p_property] {
	    set symbol [bySymbol::get_symbol $p_symbol]
	    if {$propertytype != "REQUIRED"} {
	    	set is_function [bySymbolDefined::get_is_function $p_symbol]
	    } else {
		# Get the link object, then find the global symbol
		# on the to-module, then find the type of the symbol.
		set p_link [byRequired_Sym_Link::get_whole $p_symbol]
		if {$p_link != ""} {
		    set p_symbollist [byGlobal_Sym_Link::get_rel $p_link]
		    foreach p_symbol2 $p_symbollist {
			if {[bySymbol::get_symbol $p_symbol2] == $symbol} {
			    set is_function [bySymbolDefined::get_is_function $p_symbol2]
			    break
			}
		    }
		} else {
		    set is_function 1
		}
	    }
	    set symboldata($symbol) "$propertytype $is_function"
	}
    }
    return
}

proc Dump {} {
    variable g_corepanel

    array set symboltable {}
    set module_count 0
    set symbol_function_count 0
    set symbol_data_count 0
    set symbol_count 0

    set fd [open corepanel.dump w]
    foreach p_module [byCorepanel_Module::get_iterator $g_corepanel] {
	incr module_count
	set modulename [bySymbol::get_symbol $p_module]
	puts $fd "Module $modulename"
	set propertytype [bySymbol::get_symbol $p_module]
	foreach p_property [byModule_Property::get_iterator $p_module] {
	    puts $fd "Property [bySymbol::get_symbol $p_property]"
	    set propertytype [bySymbol::get_symbol $p_property]
	    foreach p_symbol [bySym_Property::get_iterator $p_property] {
		puts $fd "Symbol [bySymbol::get_symbol $p_symbol]"
		if {$propertytype != "REQUIRED"} {
		    set is_function [bySymbolDefined::get_is_function $p_symbol]
		    puts $fd "is_function $is_function"
		    puts $fd "is_bss [bySymbolDefined::get_is_bss $p_symbol]"
		    if {$is_function} {
			incr symbol_function_count
		    } else {
			incr symbol_data_count
		    }
		} else {
		    incr symbol_count
		}
	    }
	    if {$propertytype != "REQUIRED"} {
	    	set symboltable($modulename:$propertytype:function) $symbol_function_count
	    	set symboltable($modulename:$propertytype:data) $symbol_data_count
	    	set symbol_function_count 0
	    	set symbol_data_count 0
	    } else {
	    	set symboltable($modulename:$propertytype) $symbol_count
	    	set symbol_count 0
	    }
	}
    }

    puts $fd "Module count: $module_count"
    foreach idx [lsort [array names symboltable]] {
	puts $fd "$idx $symboltable($idx)"
    }
    close $fd
}

proc Dump_Linkage {} {
    variable g_corepanel

    set fd [open corepanel_linkage.dump w]
    foreach p_module [byCorepanel_Module::get_iterator $g_corepanel] {
	set modulename [bySymbol::get_symbol $p_module]
	puts $fd "Module:$modulename"

	# The ---Requires--- section lists all the required symbols and
	# the owner modules for those symbols.
	puts $fd "---Requires---"
	set linklist [byModule_Link::graph_get_from_iterator $p_module]
	foreach p_link $linklist {
	    set p_to_module [byModule_Link::graph_get_vertex_to $p_link]
	    set to_modulename [bySymbol::get_symbol $p_to_module]
	    puts $fd "Module $to_modulename"
	    set requiredsymbollist [byRequired_Sym_Link::get_iterator $p_link]
	    foreach p_symbol $requiredsymbollist {
		set symbolname [bySymbol::get_symbol $p_symbol]
	        puts $fd "       $symbolname"
	    }	
	}
	puts $fd ""

	# The ---Provides--- section lists all the global symbols and
	# the user modules for those symbols.
	puts $fd "---Provides---"
    	set p_property [byModule_Property::get_part $p_module GLOBAL]
	foreach p_symbol [bySym_Property::get_iterator $p_property] {
	    set symbolname [bySymbol::get_symbol $p_symbol]
	    set is_function [bySymbolDefined::get_is_function $p_symbol]
	    puts $fd "$symbolname $is_function"
	    set linklist [byGlobal_Sym_Link::get_rel $p_symbol]
	    foreach p_link $linklist {
	    	set p_from_module [byModule_Link::graph_get_vertex_from $p_link]
		set modulename [bySymbol::get_symbol $p_from_module]
	        puts $fd "       $modulename"
	    }
        }	    
	puts $fd ""
    }
    close $fd
}

proc Dump_Symbol_Dependency {} {
    global tcl_platform
    variable g_corepanel

    array set symboltable {}

    set fd [open corepanel_symbol_depend.dump w]
    foreach p_module [byCorepanel_Module::get_iterator $g_corepanel] {
	set modulename [bySymbol::get_symbol $p_module]
	if {$tcl_platform(platform) != "windows"} {
	    puts $fd "Module:$modulename"
	}	
	foreach property "GLOBAL LOCAL" {
	    set p_property [byModule_Property::get_part $p_module $property]
	    foreach p_symbol [bySym_Property::get_iterator $p_property] {
		set fromsymbol [bySymbol::get_symbol $p_symbol]
		set from_is_function [bySymbolDefined::get_is_function $p_symbol] 

		set linklist [bySymbol_Depend::graph_get_from_iterator $p_symbol]
		foreach p_link $linklist {
	    	    set p_to_symbol [bySymbol_Depend::graph_get_vertex_to $p_link]
		    set tosymbol [bySymbol::get_symbol $p_to_symbol]
		    set p_to_property [bySym_Property::get_whole $p_to_symbol]
		    set to_property [bySymbol::get_symbol $p_to_property]
		    set to_is_function ""
		    if {$to_property != "REQUIRED"} {
			set to_is_function [bySymbolDefined::get_is_function $p_to_symbol] 
		    }
		    if {$tcl_platform(platform) != "windows"} {
		    	puts $fd "$fromsymbol $property $from_is_function -> \
                                  $tosymbol $to_property $to_is_function"
		    } else {
		    	puts $fd "$modulename $fromsymbol $property $from_is_function -> \
                                  $tosymbol $to_property $to_is_function"
		    }
		}
	    }
	}
    }
    close $fd
}

proc Check_Unresolved_Globals {} {
    variable g_corepanel

    set fd [open corepanel_unresolved.dump w]
    foreach p_module [byCorepanel_Module::get_iterator $g_corepanel] {
	set modulename [bySymbol::get_symbol $p_module]

	# The ---Requires--- section lists all the required symbols and
	# the owner modules for those symbols.
	set p_symbollist ""
	set linklist [byModule_Link::graph_get_from_iterator $p_module]
	foreach p_link $linklist {
	    set p_symbollist [concat $p_symbollist \
	         [byRequired_Sym_Link::get_iterator $p_link]]
	}
	set p_reqsymbollist [get_p_symbollist $p_module REQUIRED]
	set unresolvedlist [ldifference $p_reqsymbollist $p_symbollist]
	if {$unresolvedlist != ""} {
	    puts $fd "Module:$modulename"
	    foreach p_symbol $unresolvedlist {
		set symbolname [bySymbol::get_symbol $p_symbol]
	        puts $fd "       $symbolname"
	    }	
	}
	puts $fd ""
    }
    close $fd
}

proc Dot_Output {loopfilterlist linkcolorlist {puredatatoggle 1}} {
    variable g_corepanel

    set fd [open graph1.dot w]
    puts $fd "digraph G \{"
    foreach p_module [byCorepanel_Module::get_iterator $g_corepanel] {
	set modulename [bySymbol::get_symbol $p_module]

	# The ---Requires--- section lists all the required symbols and
	# the owner modules for those symbols.
	set linklist [byModule_Link::graph_get_from_iterator $p_module]
	foreach p_link $linklist {
	    set p_to_module [byModule_Link::graph_get_vertex_to $p_link]
	    set to_modulename [bySymbol::get_symbol $p_to_module]
	    if {[lsearch $loopfilterlist "$modulename $to_modulename"] != -1} {
		continue
	    }
	    if {[lsearch $linkcolorlist "$modulename $to_modulename"] != -1} {
	    	puts $fd "$modulename -> $to_modulename \[color=red\]\;"
	    } else {
		# Check for pure data dependency i.e. if modulename
		# depends on just the data provided by to_modulename.
		# If true, change link output direction, and assign it
		# a green colour.
		set p_datasymbollist [get_data_p_symbollist $to_modulename GLOBAL]
		set p_globalsymlist [byGlobal_Sym_Link::get_rel $p_link]
		if {$puredatatoggle} {
		    if {[ldifference $p_globalsymlist $p_datasymbollist] != ""} {
	    	    	puts $fd "$modulename -> $to_modulename\;"
		    } else {
		    	puts $fd "$to_modulename -> $modulename \[color=green\]\;"
		    }
		} else {
	    	    puts $fd "$modulename -> $to_modulename\;"
	    	}
	    }
	}
    }
    puts $fd "\}"
    close $fd
}

proc Save_Corepanel {filename} {
    variable g_corepanel
    malloc::set_var corepanel $g_corepanel
    malloc::save $filename
}

proc Load_Corepanel {filename} {
    variable g_corepanel
    malloc::restore $filename
    set g_corepanel [malloc::get_var corepanel]
}

}
