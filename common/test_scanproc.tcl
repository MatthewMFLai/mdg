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
source glob-r.tcl

proc init {filename} {
    array set symboldata {}
    CorePanel::Get_Symbol_Summary [lindex [split $filename "."] 0] symboldata
    Scanproc::Init [array names symboldata]
}

proc get_proc_name {line symbollist} {
    foreach procname $symbollist {
    	set idx [string first $procname $line]
	if {$idx > 0} {
	    # We want to avoid the case where we match "foo"
	    # with void foo_123(...)
	    set len [string length $procname]
	    set idx2 [expr $idx + $len]
	    if {[string index $line $idx2] == " " || 
            	[string index $line $idx2] == "(" } {
		   return $procname 
	    }
	}
    }
    return ""
}

set use_filterlist 0
set filterfile [lindex $argv 0]
set filterlist ""
if {[info exists filterfile] && $filterfile != ""} {
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
if {$filterlist != ""} {
    set use_filterlist 1
}

set procfilterfile [lindex $argv 1]
set procfilterlist ""
set fd [open $procfilterfile r]
while {[gets $fd line] > -1} {
    if {[string first "#" $line] == 0} {
        continue
    }
    lappend procfilterlist $line
}
close $fd

CorePanel::Load_Corepanel corepanel.dat
set checkpoint 0
set fd3 [open chkpt.map w]

foreach module [glob-r /disk2/Source] {
    if {[string range $module end-1 end] != ".c"} {
        continue
    }

set modulename [lindex [split $module "/"] end]
set modulename [string range $modulename 0 end-2]

if {[file exists /disk2/corepanel/temp/$modulename.i] == 0} {
    continue
}

if {$use_filterlist} {
    if {[lsearch $filterlist $modulename] == -1} {
    	continue
    }
}
 
init $modulename.i
Scanproc::Run /disk2/corepanel/temp/$modulename.i

puts "Processing $module..."

array set symboldata {}
CorePanel::Get_Symbol_Summary $modulename symboldata

# The procstrlist looks like {{23 ...} {40 ...} ...} and we only need
# the line numbers from each string.
set linenumbers ""
foreach line [Scanproc::Get_Marker /disk2/corepanel/temp/$modulename.i] {
    lappend linenumbers [lindex $line 0]    
}
lappend linenumbers -1

set fd [open $module r]
# Module looks something like /disk2/Source/abc.c or
# /disk2/Source/comms/def.c or /disk2/Source/eventBuffer/fgi.c
# We want to write to another Source directory so replace
# the "Source" with "Source_new" and make sure the "Source_new"
# subdirectory is pre-created before running this script file!!!
regsub "Source" $module "Source_new" module_new
#set fd2 [open $module.new w]
set fd2 [open $module_new w]

set currlinenumber 0 
set linenumber [lindex $linenumbers 0]

set symbollist [array names symboldata]

while {[gets $fd line] > -1} {
    incr currlinenumber
    puts $fd2 $line
    if {$currlinenumber != $linenumber} {
	continue
    }
    set procname [get_proc_name $line $symbollist]
    while {1} {
    	gets $fd line
        incr currlinenumber
    	puts $fd2 $line
	if {[string index [string trim $line] 0] == "\{"} {
	    break
	}
    }
    if {[lsearch $procfilterlist $modulename:$procname] == -1} {
    	puts $fd2 "sendChkptCommand($checkpoint);"
    } else {
    	puts $fd2 "//sendChkptCommand($checkpoint);"
    }
    puts $fd3 "$checkpoint $modulename:$procname"
    set linenumbers [lrange $linenumbers 1 end] 
    set linenumber [lindex $linenumbers 0]
    incr checkpoint
} 
close $fd
close $fd2
Scanproc::Clear
unset symboldata
}

close $fd3
puts "Checkpoint = $checkpoint"
