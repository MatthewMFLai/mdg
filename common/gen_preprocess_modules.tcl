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

if {0} {
    This script goes through the given directory (and subdirectories
    recursively) to locate all the .c modules. It then invokes the
    pic30-gcc on each module to produce the preprocessed module. 
}

if { [llength $argv] != 2 } {
    puts "Usage: gen_preprocess_modules.tcl <dir name> <outdir name>"
    puts "Example: gen_preprocess_modules.tcl c:/projects/corepanel/mlai/Source c:/temp"
    exit -1
}

proc glob-r {{dir .}} {
    set res {}
    foreach i [lsort [glob -nocomplain -dir $dir *]] {
        if {[file type $i]=="directory"} {
            eval lappend  res [glob-r $i]
        } else {
	    if {[string first ".c" $i] > 0} {
            	lappend res $i
	    }
        }
    }
    set res
}

set dirname [lindex $argv 0]
set outdirname [lindex $argv 1]

set modulelist [glob-r $dirname]
if {$modulelist == ""} {
    puts "No modules found!"
    exit -1
}

set suffix ".i"
foreach modulepath $modulelist {
    set modulename [lindex [split $modulepath "/"] end]
    set modulename [lindex [split $modulename "."] 0]
    puts "processing $modulename ..."
    #Need to figure out how to handle the space in the subdirectory.
    catch {exec cpp -IC:/Bentel/B070_Kyo_Evo/codice/panel_src -IC:/Bentel/B070_Kyo_Evo/codice/FreeRTOS_src/Source/include -IC:/Bentel/B070_Kyo_Evo/codice/panel_src/USB/Include/MDD\ File\ System -IC:/Bentel/B070_Kyo_Evo/codice/FreeRTOS_src/Source/portable/MPLAB/PIC32MX -IC:/Bentel/B070_Kyo_Evo/codice/panel_src/USB/Include -IC:/Bentel/B070_Kyo_Evo/codice/panel_src/USB -IC:/Bentel/B070_Kyo_Evo/codice/panel_src/USB/Include/USB -IC:/Bentel/B070_Kyo_Evo/codice/panel_src/V21 -IC:/Bentel/B070_Kyo_Evo/codice/panel_src/V23 -IC:/Bentel/B070_Kyo_Evo/codice/panel_src/AES -IC:/Bentel/B070_Kyo_Evo/codice/panel_src/Audio_G726 -D USEREALTIMECLOCK=1 -D __PIC32MX__=1 $modulepath} rc
    set filename $outdirname/$modulename$suffix
    set fd [open $filename w]
    puts $fd $rc
    close $fd 
}

exit 0
