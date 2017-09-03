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

namespace eval Scanproc {

    variable m_procarray
    variable m_dataarray
    variable m_proclist
    variable m_datalist
    variable m_markerlist
    variable m_proclinelist

proc Init {proclist {datalist ""}} {
    variable m_procarray
    variable m_dataarray
    variable m_proclist
    variable m_datalist
    variable m_proclinelist
    array set m_procarray {}
    array set m_dataarray {}
    set m_proclist $proclist
    set m_datalist $datalist
    set m_markerlist ""
    set m_proclinelist ""
}

proc Clear {} {
    variable m_procarray
    variable m_dataarray
    variable m_proclist
    variable m_datalist
    variable m_markerlist
    variable m_proclinelist

    unset m_procarray
    array set m_procarray {}
    unset m_dataarray
    array set m_dataarray {}
    set m_proclist ""
    set m_datalist ""
    set m_markerlist ""
    set m_proclinelist ""
}

proc Get_Iter {} {
    variable m_procarray
    return [array names m_procarray]
}

proc Get_Data_Iter {} {
    variable m_dataarray
    return [array names m_dataarray]
}

proc Dump {filename} {
    variable m_procarray
    variable m_dataarray

    set fd [open $filename w]
    foreach idx [array names m_procarray] {
	puts $fd $idx
	puts $fd $m_procarray($idx)
    }
    puts $fd ""
    foreach idx [array names m_dataarray] {
	puts $fd $idx
	puts $fd $m_dataarray($idx)
    }

    close $fd
    return
}

proc Get_Proc {name} {
    variable m_procarray
    if {[info exists m_procarray($name)]} {
	return $m_procarray($name)
    } else {
	return ""
    }
}

proc Get_Data {name} {
    variable m_dataarray
    if {[info exists m_dataarray($name)]} {
	return $m_dataarray($name)
    } else {
	return ""
    }
}

proc Get_Procline {} {
    variable m_proclinelist
    return $m_proclinelist
}

# Return the line number that corresponds to the proceudre definition
# in the .c module. Use [lindex $line 0] to get the number.
proc Get_Marker {filename} {
    variable m_markerlist
   
    set rc "" 
    set fd [open $filename r]
    foreach marker $m_markerlist {
	seek $fd $marker
	if {[gets $fd line] > -1} {
	    #puts $line
	    lappend rc [string trim $line]
	} else {
	    puts "eof reached!"
	    close $fd
	    return ""
	}
    }
    close $fd
    return $rc
}

proc Run {filename} {
    variable m_procarray
    variable m_proclist
    variable m_markerlist
    variable m_proclinelist

    set fd [open $filename r]

    set pattern "#" 
    set state SCAN_PROCEDURE_LINE

    set procname ""
    set procbody ""
    set procline ""
    set space " "
    set marker ""

    #set fd2 [open tmp.txt w]
    while {[gets $fd line] > -1} {
	#puts $fd2 $line
	#puts $fd2 $state
        switch -- $state \
	    SCAN_PROCEDURE_LINE {
		set line [string trim $line]
	        if {[string first $pattern $line] == 0} {
        	    set marker [expr [tell $fd] - [string length $line]]
		    continue
	        }
	        if {[string first "typedef" $line] == 0} {
		    continue
	        }
	        if {[string first "extern" $line] == 0} {
		    continue
	        }
	        if {[string index $line end] == "\;"} {
		    continue
	        }
	        if {[string match "*(*)" $line] == 1} {
		    append procline $line$space
	            set state SCAN_OPEN_BRACE
		    continue
		}
	        if {[string match "*(*)*" $line] == 1 &&
                    [string index $line end] == "\{"} {
		    append procline $line$space
                # Very ugly, need to clean this one up!!!
		set idx -1
		foreach procname $m_proclist {
		    set idx [string first $procname $procline]
		    if {$idx > 0} {
			# We want to avoid the case where we match "foo"
			# with void abc_foo(...) or abcfoo(...)
			set idx2 [expr $idx - 1]
			set pre_char [string index $procline $idx2]
			if {[string is alnum $pre_char] ||
			    $pre_char == "-" || $pre_char == "_"} {	
			    continue 
			}
			# We want to avoid the case where we match "foo"
			# with void foo_123(...)
			set len [string length $procname]
			set idx2 [expr $idx + $len]
			if {[string index $procline $idx2] == " " || 
                            [string index $procline $idx2] == "(" } {
			    break
			}
		    }
		}
		if {$idx == -1} {
		    # We find the procedure body, but there is no
		    # matching procedure name! This is possible since
		    # we are scanning the preprocessed source code,
		    # and the symbol list really represents the data
		    # from the compiled object modules, and there is
		    # always the possibility that the procedure body
		    # is ignored due to conditional compiling. For now
		    # we just use the special NONAME as the procedure
		    # name and ignore it after parsing the complete
		    # procedure body.
		    set procname NONAME
		}
	        set state SCAN_CLOSE_BRACE
	        set bracecount 1
		continue
                # End- Very ugly, need to clean this one up!!!
		}
	        if {[string match "*(*" $line] == 1} {
		    #puts "partial match: $line"
		    append procline $line
		    set state SCAN_MORE_PROCEDURE_LINE
		    continue
	        }

    	    } SCAN_MORE_PROCEDURE_LINE {
		#puts "check line = $line"
	        if {[string index $line end] == "\;"} {
		    set procline ""
		    set marker ""
		    set state SCAN_PROCEDURE_LINE
		    continue
	        }
		append procline $line
	        if {[string match "*(*)" $procline] == 0} {
		    continue
	        }
	        set state SCAN_OPEN_BRACE

    	    } SCAN_OPEN_BRACE {
	        set line [string trim $line]
	        if {[string index $line end] == "\;"} {
	    	    set state SCAN_PROCEDURE_LINE
		    set procline ""
		    set marker ""
		    continue
	        }
	        if {[string index $line 0] != "\{"} {
	            append procline $line$space
		    continue
	        }
	        if {[string index $line end] == "\}"} {
		    # A 1-line procedure. To be handled later???
	            set state SCAN_PROCEDURE_LINE
		    continue
	        }
		#puts "target proc line = $procline"
		set idx -1
		foreach procname $m_proclist {
		    set idx [string first $procname $procline]
		    if {$idx > 0} {
			# We want to avoid the case where we match "foo"
			# with void abc_foo(...) or abcfoo(...)
			set idx2 [expr $idx - 1]
			set pre_char [string index $procline $idx2]
			if {[string is alnum $pre_char] ||
			    $pre_char == "-" || $pre_char == "_"} {	
			    continue 
			}
			# We want to avoid the case where we match "foo"
			# with void foo_123(...)
			set len [string length $procname]
			set idx2 [expr $idx + $len]
			if {[string index $procline $idx2] == " " || 
                            [string index $procline $idx2] == "(" } {
			    break
			}
		    }
		}
		if {$idx == -1} {
		    # We find the procedure body, but there is no
		    # matching procedure name! This is possible since
		    # we are scanning the preprocessed source code,
		    # and the symbol list really represents the data
		    # from the compiled object modules, and there is
		    # always the possibility that the procedure body
		    # is ignored due to conditional compiling. For now
		    # we just use the special NONAME as the procedure
		    # name and ignore it after parsing the complete
		    # procedure body.
		    set procname NONAME
		}
	        set state SCAN_CLOSE_BRACE
	        set bracecount 1

    	    } SCAN_CLOSE_BRACE {
	    	set tmpline [string trim $line]
	        if {[string first "#" $tmpline] == 0} {
		    continue
	        }

	        set leftbracecount [regsub -all "{" $line "{" line]
	        incr bracecount $leftbracecount
	        set rightbracecount [regsub -all "}" $line "}" line]
	        set bracecount [expr $bracecount - $rightbracecount] 
	        if {$bracecount > 0} {
		    append procbody $line$space
		    continue
	        }

		# We want to exclude symbol name surrounded by
		# quotes like "".
		while {1} {
		    set idx [string first "\"" $procbody]
		    if {$idx == -1} {
			break
		    }
		    set idx2 [string first "\"" $procbody [expr $idx + 1]]
		    if {$idx2 == -1} {
			break
		    }
		    #puts "Exclude symbol inside quotes."
		    #puts [string range $procbody $idx $idx2]
		    set procbody [string replace $procbody $idx $idx2 ""]
		}
		if {$procname != "NONAME"} {
		    set m_procarray($procname) $procbody
		    lappend m_proclinelist $procline
		    # The marker can be {}, not sure why now,
		    # so just don't put it in if it is {}!
		    if {$marker != ""} {
		    	lappend m_markerlist $marker
		    }
		}
	    	set procbody ""
	    	set procname ""
		set procline ""
		set marker ""
	    	set state SCAN_PROCEDURE_LINE
    	    }
    }
    close $fd
    #close $fd2
}

proc Run_Data {filename} {
    variable m_dataarray
    variable m_datalist

    set fd [open $filename r]

    set state SCAN_LINE_WITH_EQUAL
    set dataname ""
    set dataline ""
    set space " "
    while {[gets $fd line] > -1} {
	set line [string trim $line]
        switch -- $state \
	    SCAN_LINE_WITH_EQUAL {
		set equalidx [string first "=" $line]
		if {$equalidx == -1} {
		    continue
		}
		if {[string first "\};" $line] != -1} {
		    # Process the line with both data name and value.
		    continue 
		}
		if {[string first ";" $line] != -1} {
		    continue
		}
		set state SCAN_LINE_CLOSE

		set idx -1
		foreach dataname $m_datalist {
		    set idx [string first $dataname $line]
		    if {$idx > 0} {
			# We want to avoid the case where we match "foo"
			# with ... = foo ...
			if {$equalidx < $idx} {
			    continue
			}
			# We want to avoid the case where we match "foo"
			# with void abc_foo(...) or abcfoo(...)
			set idx2 [expr $idx - 1]
			set pre_char [string index $line $idx2]
			if {[string is alnum $pre_char] ||
			    $pre_char == "-" || $pre_char == "_"} {	
			    continue 
			}
			# We want to avoid the case where we match "foo"
			# with void foo_123(...)
			set len [string length $dataname]
			set idx2 [expr $idx + $len]
			if {[string index $line $idx2] == " " ||
                            [string index $line $idx2] == "\["} {
			    break
			}
		    }
		}
		if {$idx == -1} {
		    # We find the procedure body, but there is no
		    # matching procedure name! This is possible since
		    # we are scanning the preprocessed source code,
		    # and the symbol list really represents the data
		    # from the compiled object modules, and there is
		    # always the possibility that the procedure body
		    # is ignored due to conditional compiling. For now
		    # we just use the special NONAME as the procedure
		    # name and ignore it after parsing the complete
		    # procedure body.
		    set dataname NONAME
		}

    	    } SCAN_LINE_CLOSE {
		if {[string first ";" $line] != -1} {
		    if {[string first "\};" $line] != -1} {
			if {$dataname != "NONAME"} {
			    append dataline $line
			    set m_dataarray($dataname) $dataline
			} else {
			    # Silent discard...
			    # puts "dataline = $dataline"
			}
		    }
		    set dataname ""
		    set dataline "" 
		    set state SCAN_LINE_WITH_EQUAL
		} else {
		    append dataline $line$space
		}

    	    } 
    }
    close $fd
}
}
