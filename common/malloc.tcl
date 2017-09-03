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

namespace eval malloc {

    variable alloc_list
    variable free_list
    variable next_id
    variable var_table

    proc init {} {
    	variable alloc_list
    	variable free_list
    	variable next_id
    	variable var_table

	set alloc_list ""	
	set free_list ""
	set next_id 0
	array set var_table {}
    }
	
    proc getmem {{datalist ""}} {
    	variable alloc_list
	variable free_list
	variable next_id

	if {$free_list != ""} {
	    set varname [lindex $free_list 0]
	    if {[llength $free_list] > 1} {
	    	set free_list [lrange $free_list 1 end]
	    } else {
		set free_list ""
	    }
	} else {
	    set varname MALLOC$next_id
	    lappend alloc_list $varname
	    incr next_id
	}

	global $varname
	array set $varname "$datalist" 
	return $varname	
    }

    proc freemem {varname} {
    	variable alloc_list
	variable free_list
	
	global $varname
	if {[info exists $varname]} {
	    unset $varname
	    lappend free_list $varname
	    set idx [lsearch $alloc_list $varname]
	    set alloc_list [lreplace $alloc_list $idx $idx]
	} else {
	    puts "$varname does not exist in global scope."
	}
    }

    proc copymem {varname} {

	global $varname
	set copy_name [malloc::getmem]
	global $copy_name
	array set $copy_name [array get $varname]
	return $copy_name
    }

    proc flatmem {varname} {
	# To return a "flattened" memory object.
	global $varname
	return [array get $varname]
    }

    proc get_var {name} {
    	variable var_table

	return $var_table($name)
    }

    proc set_var {name value} {
    	variable var_table

	set var_table($name) $value
    }

    proc save {filename} {
    	variable alloc_list
	variable free_list
    	variable next_id
    	variable var_table

	set fd [open $filename w]
	if {$alloc_list == ""} {
	    puts $fd "set alloc_list \"\""
	} else {
	    puts $fd "set alloc_list \[ list $alloc_list \]"
	}
	if {$free_list == ""} {
	    puts $fd "set free_list \"\""
	} else {
	    puts $fd "set free_list \[ list $free_list \]"
	}
	puts $fd "set next_id $next_id"
	if {[array names var_table]  == ""} {
	    puts $fd "array set var_table \{\}"
	} else {
	    puts $fd "array set var_table \{ [array get var_table] \}"
	}

	foreach varname $alloc_list {
	    global $varname
	    puts $fd "global $varname"
	    puts $fd "array set $varname \{ [array get $varname] \}"
	}
    }

    proc restore {filename} {
    	variable alloc_list
	variable free_list
    	variable next_id
    	variable var_table

	if {[file exists $filename]} {
	    source $filename
	} else {
	    puts "$filename cannot be found."
	} 
    }

}
