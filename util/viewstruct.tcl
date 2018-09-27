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
        if {[string first "an_top" $datafile] != -1} {
            continue
        }
        if {[string first "an_fsm" $datafile] != -1} {
            continue
        }
        puts "Processing $datafile..."
        Scanstruct::Run $datafile
    }
    Scanstruct::Post_Process_Substructs
    Scanstruct::Create_Objects
    return
}

Scanstruct::Init
set c .c
pack [canvas $c] -expand true -fill both
set xc 0
set yc 0
focus $c 
bind $c <Button-1> {set xc %x; set yc %y} 
bind $c <B1-Motion>  {moveItems  %W %x %y}
