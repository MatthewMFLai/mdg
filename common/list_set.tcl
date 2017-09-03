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

if {0} {
The following commands are basic set operations for Tcl lists.
They are part of a larger library for functional programming in Tcl
that's possible to find at http://wiki.hping.org/133. The proposed 
commands try to run in O(M+N) time complexity, and to don't mess 
with the order of the elements when possible.
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

 proc lunion {a b} {
     foreach e $a {
 	set x($e) {}
     }
     foreach e $b {
 	if {![info exists x($e)]} {
 	    lappend a $e
 	}
     }
     return $a
 }

 proc ldifference {a b} {
     foreach e $b {
 	set x($e) {}
     }
     set result {}
     foreach e $a {
 	if {![info exists x($e)]} {
 	    lappend result $e
 	}
     }
     return $result
 }

 proc in {list element} {
     expr {[lsearch -exact $list $element] != -1}
 }
