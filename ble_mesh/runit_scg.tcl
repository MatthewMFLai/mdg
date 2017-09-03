puts "Generate static call graph data."
puts "================================"
#exec ../bin/tclsh ../common/corepanel_test2.tcl corepanel.dat "C:/mdg/PC9155/List" 
exec ../bin/tclsh ../common/corepanel_test2.tcl corepanel.dat [lindex $argv 0] 

puts "Generate simplified static call graph data."
puts "==========================================="
#exec ../bin/tclsh ../common/corepanel_test2.tcl corepanel.dat "C:/mdg/PC9155/List" s
exec ../bin/tclsh ../common/corepanel_test2.tcl corepanel.dat [lindex $argv 0] s

# custom processing of Main_high_lev.dot
#puts "Generate custom Main_high_lev call graph data."
#puts "=============================================="
#source filter_main_high_lev.tcl
#filter_main_high_lev graphviz/Main_high_lev.dot
#filter_main_high_lev graphviz/Main_high_lev.sim.dot
#exec dot -Tpdf graphviz/Main_high_lev.proc_only.dot -o graphviz/Main_high_lev.proc_only.pdf 
#exec dot -Tpdf graphviz/Main_high_lev.sim.proc_only.dot -o graphviz/Main_high_lev.sim.proc_only.pdf 


