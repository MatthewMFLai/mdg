# Copyright (c) 2018, Matthew Lai <mmlai@sympatico.ca> 
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

namespace eval Scanstruct {

    variable m_struct
    variable m_objects
    variable m_objname
    variable m_objid

proc extract_struct_name {line} {
    if {[string index $line end] == "\{"} {
        append line "\}"
    }
    return [lindex $line 1]
}

proc Init {} {
    variable m_struct
    variable m_objects
    variable m_objname
    variable m_objid

    if {[info exists m_struct]} {
        unset m_struct
    }
    array set m_struct {}

    if {[info exists m_objects]} {
        unset m_objects
    }
    array set m_objects {}

    set m_objname "Node"
    set m_objid 0
}

proc Clear {} {
    variable m_struct
    variable m_objects
    variable m_objid

    unset m_struct
    array set m_struct {}
    unset m_objects
    array set m_objects {}
    set m_objid 0
}

proc Dump {filename selector} {
    variable m_struct
    variable m_objects

    if {$selector == "struct"} {
        set name m_struct
    } else {
        set name m_objects
    }

    set fd [open $filename w]
    foreach {idx lines} [array get $name] {
        puts $fd $idx
        foreach line $lines { 
	    puts $fd $line
        } 
        puts $fd ""
    }
    close $fd
    return
}

proc Get_Struct {name} {
    variable m_struct
    if {[info exists m_struct($name)]} {
	return $m_struct($name)
    } else {
	return ""
    }
}

proc get_object {structname} {
    variable m_struct
    variable m_objects

    set rc ""
    if {![info exists m_struct($structname)]} {
        return $rc
    }
    
    foreach idx [array names m_objects] {
        set line [lindex $m_objects($idx) 0]
        if {[lindex $line 1] == $structname} {
	    set rc $idx
            break
        }
    }
    return $rc
}

# Example of substructure
#struct adapt_avg_buff_t
#{
#uint8_t idx;
# union
# {
#  int8_t s[4];
#  uint8_t u[4];
# }
# samples;
#
# union
# {
#  int16_t s;
#  uint16_t u;
# }
# accum;
# uint8_t num_buff_samples;
# uint8_t num_accum_samples;
# uint8_t num_avg_samples;
#};

proc Run {filename} {
    variable m_struct

    set fd [open $filename r]

    set state SCAN_LINE_WITH_STRUCT
    set struct "struct"
    set union "union"
    set substructs "struct union"
    set uscore "_"
    set space " "
    set semicolon ";"
    set hash "#"
    set structname ""
    set openbrace "\{"
    set closebraceonly "\}"
    set closebrace "\}*\;"
    set dataline ""

    while {[gets $fd line] > -1} {
	set line [string trim $line]
        if {$line == ""} {
            continue
        }
        set idx [string first $hash $line]
        if {$idx == 0} {
            continue
        }
      
        switch -- $state \
	    SCAN_LINE_WITH_STRUCT {
		set idx [string first $struct $line]
		set idx2 [string first $union $line]
		if {$idx != 0 && $idx2 != 0} {
		    continue
		}

		if {[string first $semicolon $line] != -1} {
		    # Ignore 'struct ... ;' 
		    continue 
		}
                set structname [extract_struct_name $line]
		if {$structname == ""} {
		    continue
		}

		if {[string first $uscore $structname] == 0} {
                    set structname ""
		    continue
		}

		if {[info exists m_struct($structname)]} {
                    set structname ""
		    continue
		}
                #puts $line

                set m_struct($structname) ""
                lappend m_struct($structname) $line
		set state SCAN_STRUCT_OPEN_BRACE

	    } SCAN_STRUCT_OPEN_BRACE {
                if {[string index $line 0] == $openbrace} {
                    #puts $line
		    set state SCAN_STRUCT_CLOSE_BRACE
                }

    	    } SCAN_STRUCT_CLOSE_BRACE {
                # puts $line 
                if {[string match $closebrace $line] ||
                    [string first $closebraceonly $line] == 0} {
                    #puts $line
		    set state SCAN_LINE_WITH_STRUCT
                    set dataline ""
                    set structname ""
                    continue 
                }
                append dataline $line$space
                if {[lsearch $substructs [lindex $line 0]] > -1 &&
                    [llength $line] == 1} {
                    set state SCAN_SUBSTRUCT_OPEN_BRACE
                    continue
                }
		if {[string first $semicolon $line] == -1} {
                    continue
                } else {
                    #puts $dataline
                    lappend m_struct($structname) [string range $dataline 0 end-1]
                    set dataline "" 
		}
 
	    } SCAN_SUBSTRUCT_OPEN_BRACE {
                if {[string index $line 0] == $openbrace} {
                    #puts $line
                    append dataline $line$space
		    set state SCAN_SUBSTRUCT_CLOSE_BRACE
                }

    	    } SCAN_SUBSTRUCT_CLOSE_BRACE {
                #puts $line
                append dataline $line$space
                if {[string first $closebraceonly $line 0] == 0} {
		    set state SCAN_SUBSTRUCT_NAME
                    continue 
                }

    	    } SCAN_SUBSTRUCT_NAME {
                if {[string first $semicolon $line] > 0} {
                    #puts $line
                    append dataline $line$space
                    lappend m_struct($structname) [string range $dataline 0 end-1]
		    set state SCAN_STRUCT_CLOSE_BRACE
                    set dataline ""
                    continue 
                }
            }
    }
    close $fd
}

proc Post_Process_Substructs {} {
    variable m_struct

    set anony "anonymous"
    set cnt 0
    set idx 0
    foreach structname [array names m_struct] {
        array set tmptable {}
        foreach line $m_struct($structname) {
            if {[string first "\{" $line] == -1} {
                incr idx
                continue
            }
            # line looks like
            # struct { int a; char b; } result;
            #

            set anonytype $anony$cnt
            set idx1 [string first "\{" $line]
            set idx2 [string last "\}" $line]
            set chgline [string replace $line $idx1 $idx2 $anonytype]
            set tmptable($idx) [list $line $chgline]
            incr idx
            incr cnt
        }

        # Update the lines that have been modified.
        foreach idx [array names tmptable] {
            set line [lindex $tmptable($idx) 0]
            set chgline [lindex $tmptable($idx) 1]

            set m_struct($structname) [lreplace $m_struct($structname) $idx $idx $chgline]

            set anonytype [lindex $chgline 1]
            set m_struct($anonytype) ""
            lappend m_struct($anonytype) [lrange $chgline 0 1]
            set fields [string trim [lindex $line 1]]
            foreach field [split $fields ";"] {
                if {$field != ""} {
                   set field [string trim $field]
                   append field ";"
                   lappend m_struct($anonytype) $field 
                }
            }
        }
        unset tmptable
        set idx 0
    }
    return
}

proc create_obj_imp {structname} {
    variable m_struct
    variable m_objects
    variable m_objname
    variable m_objid

    set const "const"
    set struct "struct"
    set union "union"
    set space " "
    set objid $m_objname$m_objid
    set m_objects($objid) ""
    incr m_objid

    set lines $m_struct($structname)
    lappend m_objects($objid) [lindex $lines 0]
    set lines [lrange $lines 1 end]  
    foreach line $lines {
        regsub ";" $line "" line
        set prefix ""
        if {[lindex $line 0] == $const} {
            set line [string trim [string map "const {}" $line]]
            set prefix "$const "
        } 
        if {[string first $struct $line] != 0 &&
            [string first $union $line] != 0} {
            lappend m_objects($objid) $prefix$line 
            continue
        }

        # Extract embedded or pointed to struct or union name.
        set tostruct [lindex $line 1]
        # 2 checks:
        # - whether tostruct is same as current structname i.e. check for a linked list
        # - whether tostruct is defined in the m_struct type dictionary
        if {$structname == $tostruct} {
            set samestruct 1
        } else {
            set samestruct 0
        }
        set definedstruct [info exists m_struct($tostruct)]

        if {$samestruct} {
            set line [string map "struct {} union {} $structname $objid" $line]
            lappend m_objects($objid) [string trim $prefix$line]
            
        } else {        
            if {$definedstruct} {
                # Recursive call.
                set toobjid [create_obj_imp $tostruct]
                # Replace the "struct tostruct" with the toobjid
                set line [string map "struct {} union {} $tostruct $toobjid" $line]
                lappend m_objects($objid) [string trim $prefix$line]
                  
            } else {
                # Cannot create the target object so just put in the line...
                lappend m_objects($objid) $prefix$line

            }
        } 
    }
    
    return $objid
}

proc Create_Objects {} {
    variable m_struct

    foreach structname [array names m_struct] {
        create_obj_imp $structname
    }
}

proc collect_objects {objid} {
    variable m_objects 

    set rc ""
    set objidprefix "Node"
    set const "const"

    foreach line $m_objects($objid) {
        if {[string first $objidprefix $line] == -1} {
            continue
        }
        if {[lindex $line 0] != $const} {
            set toobjid [lindex $line 0]
        } else {
            set toobjid [lindex $line 1]
        }
            
        if {$objid == $toobjid} {
            continue
        }
        lappend rc $toobjid
        set rc [concat $rc [collect_objects $toobjid]]
    } 
    return $rc
}

# Create the node lines like these in a dot file
# "node10" [
# label = "<f0> (nil)| <f1> | <f2> |-1"
# shape = "record"
# ];
proc create_node_dot {objid} {
    variable m_objects

    set objidprefix "Node"
    set const "const"
    set rc ""
    set fcnt 0
    append rc "\"$objid\" \["
    append rc "\n"
    append rc "label = \""
    foreach line $m_objects($objid) {
        if {[string first $objidprefix $line] != -1} {
            set line_changed [string map "$const {}" $line]
            set toobjid [lindex $line_changed 0]
            set line [string map "$toobjid {}" $line]
        }
        append rc "<f$fcnt> $line | "
        incr fcnt
    }
    set idx [string last "|" $rc]
    incr idx -1
    set rc [string range $rc 0 $idx]
    append rc "\"\n"
    append rc "shape = \"record\""
    append rc "\n"
    append rc "\];"
    append rc "\n"
    return $rc
}

# Create the link lines like these in a dot file
#"node0":f0 -> "node1":f0 [
#id = 0
#];
proc create_link_dot {objid p_linkid} {
    upvar $p_linkid linkid
    variable m_objects

    set objidprefix "Node"
    set const "const"
    set rc ""
    set fcnt 0
    foreach line $m_objects($objid) {
        if {[string first $objidprefix $line] != -1} {
            set line [string map "$const {}" $line]
            set toobjid [lindex $line 0]
            append rc "\"$objid\":f$fcnt -> \"$toobjid\":f0 \["
            append rc "\n"
            append rc "id = $linkid"
            append rc "\n"
            append rc "\];\n"
            incr linkid
        }
        incr fcnt
    }
    return $rc
}

proc Create_Objects_Dot {dotfile structname} {
    variable m_objects 

    set objid [get_object $structname]
    if {$objid == ""} {
        return
    }

    set objlist "" 
    lappend objlist $objid
    set objlist [concat $objlist [collect_objects $objid]]
    set nodestr ""
    foreach objid $objlist {
        append nodestr [create_node_dot $objid]
    }

    set linkstr ""
    set linkid 0
    foreach objid $objlist {
        append linkstr [create_link_dot $objid linkid]
    }

    set fd [open $dotfile w]
    set header ""
    append header "digraph g \{\n"
    append header "graph \[\n"
    append header "rankdir = \"LR\"\n"
    append header "\];\n"
    append header "node \[\n"
    append header "fontsize = \"12\"\n"
    append header "\];\n"
    append header "edge \[\n"
    append header "\];"
    puts $fd $header
    puts $fd $nodestr
    puts $fd $linkstr
    puts $fd "\}"
    close $fd
    return $objlist
}

}
