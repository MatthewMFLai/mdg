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

namespace eval byGlobal_Sym_Link {
# Substitue <assoc> with the name of the
# pattern instance.
# Substitue <whole> and <part> with the
# names of the application structures.
proc add_rel {p_entity p_entity2} {
    upvar #0 $p_entity entity
    upvar #0 $p_entity2 entity2 

    set idx [lsearch $entity(lattice:byGlobal_Sym_Link:rel_list) $p_entity2]
    if {$idx == -1} {
    	lappend entity(lattice:byGlobal_Sym_Link:rel_list) $p_entity2
    }

    set idx [lsearch $entity2(lattice:byGlobal_Sym_Link:rel_list) $p_entity]
    if {$idx == -1} {
    	lappend entity2(lattice:byGlobal_Sym_Link:rel_list) $p_entity
    }

    return 0
}

proc remove_rel {p_entity p_entity2} {
    upvar #0 $p_entity entity
    upvar #0 $p_entity2 entity2

    set idx [lsearch $entity(lattice:byGlobal_Sym_Link:rel_list) $p_entity2]
    if {$idx > -1} {
	set entity(lattice:byGlobal_Sym_Link:rel_list) [lreplace $entity(lattice:byGlobal_Sym_Link:rel_list) $idx $idx]
    }

    set idx [lsearch $entity2(lattice:byGlobal_Sym_Link:rel_list) $p_entity]
    if {$idx > -1} {
	set entity2(lattice:byGlobal_Sym_Link:rel_list) [lreplace $entity2(lattice:byGlobal_Sym_Link:rel_list) $idx $idx]
    }

    return 0
}

proc get_rel {p_entity} {
    upvar #0 $p_entity entity

    return $entity(lattice:byGlobal_Sym_Link:rel_list)
}

proc init_entity {p_entity} {
    upvar #0 $p_entity entity
    set entity(lattice:byGlobal_Sym_Link:rel_list) ""
}

}
