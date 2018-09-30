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

proc view {structname} {
    global c

    if {[Scanstruct::Get_Struct $structname] == ""} {
        return
    }
    $c delete all 
    Scanstruct::Create_Objects_Dot temp.dot $structname
    exec dot -Ttk temp.dot -o temp.tk
    zoominit $c
    source temp.tk
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

tk_setPalette SkyBlue1
 
Scanstruct::Init

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
        .mbar.list insert end $structname
    } 
}	
.mbar.file.m add command -label "Reload" -command {
}
.mbar.file.m add command -label "Exit" -command exit

scrollbar .mbar.scroll -command ".mbar.list yview"
listbox .mbar.list -yscroll ".mbar.scroll set" \
	-width 40 -height 6
pack .mbar.list .mbar.scroll -side left -fill y -expand 1

bind .mbar.list <Double-1> {
    view [selection get]
}

set c .c
pack [canvas $c] -expand true -fill both
set xc 0
set yc 0
focus $c 
bind $c <Button-1> {set xc %x; set yc %y} 
bind $c <B1-Motion>  {moveItems  %W %x %y}
