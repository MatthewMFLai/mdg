#!/bin/sh
# \
exec tclsh $0 $@

set infile [lindex $argv 0]
set template [lindex $argv 1]
set outfile [lindex $argv 2]

set fd [open $template r]
set data [read $fd]
close $fd

set fd [open $infile r]
set fd2 [open $outfile w]
gets $fd line
puts $fd2 $line
puts $fd2 $data
while {[gets $fd line] > -1} {
    puts $fd2 $line
}
close $fd
close $fd2
exit 0
