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

namespace eval bySymbol {
proc set_symbol {p_generic attr} {
    upvar #0 $p_generic generic

    set generic(symbol:bySymbol:symbol) $attr
}

proc get_symbol {p_generic} {
    upvar #0 $p_generic generic

    return $generic(symbol:bySymbol:symbol)
}

proc init {p_generic} {
    upvar #0 $p_generic generic
    set generic(symbol:bySymbol:symbol) ""
}

proc remove {p_generic} {
    upvar #0 $p_generic generic
    unset generic(symbol:bySymbol:symbol)
}

proc getattrname {} {
    return "symbol"
}
}
