set filedir [lindex $argv 0]
set outfile [lindex $argv 1]
set fd_out [open $outfile w]

set code_exp {([\d]+) bytes of CODE  memory}
set const_exp {([\d]+) bytes of CONST memory}
set data_exp {([\d]+) bytes of DATA  memory}

set datasizelist ""
array set datasizetable {}

foreach filename [glob $filedir/*.lst] {
    set fd [open $filename r]
	set data [read $fd]
	close $fd
	
	puts $fd_out $filename
	if {[regexp $code_exp $data -> codesize]} {
	    puts $fd_out "CODE $codesize"
		unset codesize
	}
	if {[regexp $const_exp $data -> constsize]} {
	    puts $fd_out "CONST $constsize"
		unset constsize
	}
	if {[regexp $data_exp $data -> datasize]} {
	    puts $fd_out "DATA $datasize"
		
		if {![info exists datasizetable($datasize)]} {
			set datasizetable($datasize) ""
		}
		lappend datasizetable($datasize) $filename
		lappend datasizelist $datasize
		unset datasize
	}
	puts $fd_out ""
}

set datasizelist [lsort -unique -decreasing -integer $datasizelist]
foreach size $datasizelist {
    puts $fd_out "$size $datasizetable($size)"
}
close $fd_out
exit 0
	