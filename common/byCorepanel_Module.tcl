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

namespace eval byCorepanel_Module {
# Substitue <assoc> with the name of the
# pattern instance.
# Substitue <whole> and <part> with the
# names of the application structures.
proc add_part {p_whole p_part} {
    upvar #0 $p_whole whole
    upvar #0 $p_part part

    set part(assoc:byCorepanel_Module:whole_ref) $p_whole
    lappend whole(assoc:byCorepanel_Module:part_list) $p_part
}

proc remove_part {p_whole p_part} {
    upvar #0 $p_whole whole
    upvar #0 $p_part part

    set idx 0
    set key $part(assoc:byCorepanel_Module:key)
    foreach p_part $whole(assoc:byCorepanel_Module:part_list) {
	upvar #0 $p_part cur_part
	if {$cur_part(assoc:byCorepanel_Module:key) == $key} {
	    set whole(assoc:byCorepanel_Module:part_list) [lreplace $whole(assoc:byCorepanel_Module:part_list) $idx $idx]
	    set part(assoc:byCorepanel_Module:whole_ref) ""
	    return 1
	}
	incr idx
    }
    return 0
}

proc get_part {p_whole key} {
    upvar #0 $p_whole whole

    foreach p_part $whole(assoc:byCorepanel_Module:part_list) {
	upvar #0 $p_part part
	if {$part(assoc:byCorepanel_Module:key) == $key} {
	    return $p_part
	}
    }
    return NULL
}

proc get_whole {p_part} {
    upvar #0 $p_part part

    return $part(assoc:byCorepanel_Module:whole_ref)
}

proc get_key {p_part} {
    upvar #0 $p_part part

    return $part(assoc:byCorepanel_Module:key)
}

proc get_iterator {p_whole} {
    upvar #0 $p_whole whole

    return $whole(assoc:byCorepanel_Module:part_list)
}

proc init_part {p_part key} {
    upvar #0 $p_part part
    set part(assoc:byCorepanel_Module:whole_ref) ""
    set part(assoc:byCorepanel_Module:key) $key
}

proc init_whole {p_whole} {
    upvar #0 $p_whole whole
    set whole(assoc:byCorepanel_Module:part_list) ""
}

}
