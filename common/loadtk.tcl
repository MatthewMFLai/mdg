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

proc zoominit {c {zfact {1.1}}} {
    # save zoom state in a global variable with the same name as the canvas handle
    upvar #0 $c data
    set data(zdepth) 1.0
    set data(idle) {}
    # add mousewheel bindings to canvas
    bind $c <Button-4> "zoom $c $zfact"
    bind $c <Button-5> "zoom $c [expr {1.0/$zfact}]"
    bind $c <MouseWheel> "if {%D > 0} {zoom $c $zfact} else {zoom $c [expr {1.0/$zfact}]}"
}
 
proc zoom {c fact} {
    upvar #0 $c data
    # zoom at the current mouse position
    set x [$c canvasx [expr {[winfo pointerx $c] - [winfo rootx $c]}]]
    set y [$c canvasy [expr {[winfo pointery $c] - [winfo rooty $c]}]]
    $c scale all $x $y $fact $fact
    # save new zoom depth
    set data(zdepth) [expr {$data(zdepth) * $fact}]
    # update fonts only after main zoom activity has ceased
    after cancel $data(idle)
    set data(idle) [after idle "zoomtext $c"]
}

proc zoomtext {c} {
    upvar #0 $c data
    # adjust fonts
    foreach {i} [$c find all] {
        if { ! [string equal [$c type $i] text]} {continue}
        set fontsize 0
        # get original fontsize and text from tags
        #   if they were previously recorded
        foreach {tag} [$c gettags $i] {
            scan $tag {_f%d} fontsize
            scan $tag "_t%\[^\0\]" text
        }
        # if not, then record current fontsize and text
        #   and use them
        set font [$c itemcget $i -font]
        if {!$fontsize} {
            set text [$c itemcget $i -text]
            if {[llength $font] < 2} {
                #new font API
                set fontsize [font actual $font -size]
            } {
                #old font API
                set fontsize [lindex $font 1]
            }
            $c addtag _f$fontsize withtag $i
            $c addtag _t$text withtag $i
        }
        # scale font
        set newsize [expr {int($fontsize * $data(zdepth))}]
        if {abs($newsize) >= 4} {
            if {[llength $font] < 2} {
                #new font api
                font configure $font -size $newsize
            } {
                #old font api
                set font [lreplace $font 1 1 $newsize] ; # Save modified font! [ljl]
            }
            $c itemconfigure $i -font $font -text $text
        } {
            # suppress text if too small
            $c itemconfigure $i -text {}
        }
    }
    # update canvas scrollregion
    set bbox [$c bbox all]
    if {[llength $bbox]} {
        $c configure -scrollregion $bbox
    } {
        $c configure -scrollregion [list -4 -4 \
              [expr {[winfo width $c]-4}] \
              [expr {[winfo height $c]-4}]]
    }
}

proc moveItems {c x y } {
    global xc yc
    
    if { [info exists ::xc] } {
        $c move all [expr {$x-$xc}] [expr {$y-$yc}]
    }   
    set xc $x
    set yc $y
}

set c .c
pack [canvas $c] -expand true -fill both
zoominit $c
set xc 0
set yc 0
focus $c 
bind $c <Button-1> {set xc %x; set yc %y} 
bind $c <B1-Motion>  {moveItems  %W %x %y}

# source in a tk file generate by the dot program
# eg. dot -Ttk foo.dot -o foo.tk
# source foo.tk
source [lindex $argv 0]

if {$tcl_platform(platform) == "windows"} {
} else {
}
