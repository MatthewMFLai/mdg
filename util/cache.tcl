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

namespace eval Cache {

    variable m_tkfiles
    variable m_structlist
    variable m_cur

proc Init {} {
    variable m_tkfiles
    variable m_structlist
    variable m_cur

    if {[info exists m_tkfiles]} {
        unset m_tkfiles
    }
    array set m_tkfiles {}

    set m_structlist ""
    set m_cur -1
    return
}

proc Get {structname} {
    variable m_tkfiles
    variable m_structlist
    variable m_cur

    set idx [lsearch $m_structlist $structname]
    if {$idx > -1} {
        set m_cur $idx
        return $m_tkfiles($structname)
    }
    return ""
}

proc Get_Next {prev_or_next} {
    variable m_tkfiles
    variable m_structlist
    variable m_cur

    if {$m_cur == -1} {
        return ""
    }

    if {$prev_or_next == "CACHE_PREV"} {
        incr m_cur -1
    
    } elseif {$prev_or_next == "CACHE_NEXT"} {
        incr m_cur

    } else {
 
    }
    if {$m_cur == -1} {
        incr m_cur
    } elseif {[llength $m_structlist] == $m_cur} {
        incr m_cur -1
    }

    return $m_tkfiles([lindex $m_structlist $m_cur])
}

proc Set {structname tkfiledata} {
    variable m_tkfiles
    variable m_structlist
    variable m_cur

    if {[lsearch $m_structlist $structname] > -1} {
        return
    }
    lappend m_structlist $structname
    incr m_cur
    set m_tkfiles($structname) $tkfiledata

    return 
}

}
