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

#!/bin/sh
# \
exec wish $0 $@

source scanstruct.tcl
source loadzoom.tcl
source cache.tcl

proc view {c structname} {

    if {[Scanstruct::Get_Struct $structname] == ""} {
        return
    }

    $c delete all
    zoominit $c

    set tkdata [Cache::Get $structname]
    if {$tkdata == ""} { 
        Scanstruct::Create_Objects_Dot temp.dot $structname
        exec dot -Ttk temp.dot -o temp.tk
        source temp.tk
       
        set fd [open temp.tk r]
        set tkfiledata [read $fd]
        close $fd
        Cache::Set $structname $tkfiledata

        file delete temp.dot
        file delete temp.tk

    } else {
        eval $tkdata

    }

    return 
}

proc view_next {prev_or_next} {
    global c

    $c delete all
    zoominit $c

    set tkdata [Cache::Get_Next $prev_or_next]
    if {$tkdata != ""} { 
        eval $tkdata
    }

    return 
}

proc load {lstdir} {
    foreach datafile [glob $lstdir/*.i] {
        #puts "Processing $datafile..."
        Scanstruct::Run $datafile
    }
    Scanstruct::Post_Process_Substructs
    Scanstruct::Create_Objects
    return
}

proc save {filename structname} {

    if {$structname == ""} {
        return
    }

    Scanstruct::Create_Objects_Dot temp.dot $structname
    exec dot -Tsvg temp.dot -o $filename 
    file delete temp.dot

    return 
}

tk_setPalette SkyBlue1
 
Scanstruct::Init
Cache::Init

frame .mbar -borderwidth 1 -relief raised
pack .mbar -fill x

menubutton .mbar.file -text "File" -menu .mbar.file.m
pack .mbar.file -side left

menu .mbar.file.m

.mbar.file.m add command -label "Open" -command {
    set dirname [tk_chooseDirectory]
    if {$dirname != ""} {
        load $dirname	
    }
    foreach structname [lsort [array names Scanstruct::m_struct]] {
        .mbar2.list insert end $structname
    } 
}	
.mbar.file.m add command -label "SaveAs" -command {
    set filename [tk_getSaveFile]
    if {$filename != ""} {
        save $filename [Cache::Get_Cur_Struct]
    }
}
.mbar.file.m add command -label "Exit" -command exit

button .mbar.b1 -text "<" -width 4 \
    -command {view_next "CACHE_PREV"}
button .mbar.b2 -text ">" -width 4 \
    -command {view_next "CACHE_NEXT"}
pack .mbar.b1 .mbar.b2 -side left

frame .mbar2 -borderwidth 1 -relief raised
pack .mbar2 -fill x

scrollbar .mbar2.scroll -command ".mbar2.list yview"
listbox .mbar2.list -yscroll ".mbar2.scroll set" \
	-width 0 -height 0
pack .mbar2.list .mbar2.scroll -side left

bind .mbar2.list <Double-1> {
    global c
    view $c [selection get]
}

bind .mbar2.list <Button-3> {
    global c2
    if {[catch {toplevel .[selection get]} top_new] != 1} {
        set c2 $top_new.canvas 
        pack [canvas $c2] -expand true -fill both
        view $c2 [selection get]
    }
}

set c .mbar2.c
pack [canvas $c] -expand true -fill both
focus $c 
