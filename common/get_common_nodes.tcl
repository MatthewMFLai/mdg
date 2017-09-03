proc populate {filename p_nodetable p_linktable} {
    upvar $p_nodetable nodetable 
    upvar $p_linktable linktable 

    set fd [open $filename r]
    while {[gets $fd line] > -1} {
	if {$line == ""} {
	    continue
	}
	if {[string first "->" $line] > 0} {
	    # Construct link table.
	    set idx [string first "\[" $line]
	    if {$idx == -1} {
		puts "ERROR: $line"
	        return
	    }
	    incr idx -1
	    set line [string range $line 0 $idx]
	    set linktable($line) 1
	    continue
	}
	if {[string first "label=" $line] > 0} {
	    # Construct node table.
	    set idx [string first "\"" $line]
	    incr idx
	    set idx2 [string first "\\" $line]
	    incr idx2 -1
	    set module [string range $line $idx $idx2]

	    set idx [string first " " $line]
	    incr idx -1
	    set node [string range $line 0 $idx]
	    
	    set nodetable($node) $module
	    continue
	} 
    }
    close $fd
}

proc runit {startnode p_nodetable p_linktable} {
    upvar $p_nodetable nodetable 
    upvar $p_linktable linktable

    set worklist ""
    set rc ""

    lappend worklist $startnode
    while {[llength $worklist] != 0} {
	puts $worklist
	# Get from head (index 0) of list.
	set node [lindex $worklist 0]
	# Reduce length of work list.
	set worklist [lrange $worklist 1 end]
	# Get link data from link table.
	foreach link [array names linktable "$node -> *"] {
	    # Get the to-node.
	    set tonode [lindex $link 2]
	    # Add to-node into both work list and result list, if it is not
	    # already present in those lists.
	    if {[lsearch $worklist $tonode] == -1} {
		lappend worklist $tonode
	    }
	    if {[lsearch $rc $tonode] == -1} {
		lappend rc $tonode
	    }
	}
    }
    return $rc
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
