puts "Clean up symbol files"
puts "===================="
file delete -force symbols.all
#file delete -force symbols.all.filtered

puts "Clean up graphviz"
puts "===================="
file delete -force graph1.dot
file delete -force graph1_rank.dot
file delete -force graph1.pdf
file delete -force -- graphviz
file mkdir graphviz

#puts "Clean up temp"
#puts "================"
#file delete -force -- temp 
#file mkdir temp

#puts "populate temp with cpp files"
#puts "================"
#exec tclsh gen_preprocess_modules.tcl C:/Bentel/B070_Kyo_Evo/codice/panel_src temp

puts "Generate filtered symbols file."
puts "==============================="
#exec ../bin/tclsh ../common/getallsymbols "C:/mdg/PC9155/Obj"
exec ../bin/tclsh ../common/getallsymbols [lindex $argv 0]
exec ../bin/tclsh custom/filter.tcl symbols.all

puts "Generate dependency graph data."
puts "==============================="
exec ../bin/tclsh ../common/corepanel_test.tcl symbols.all.filtered graphs/module.filter
exec ../bin/tclsh ../common/add_rank.tcl graph1.dot graphs/bare_template.dat graph1_rank.dot
exec dot -Tpdf graph1_rank.dot -o graph1.pdf
#exec ../bin/tclsh ../common/corepanel_test.tcl symbols.all.filtered

puts "Generate static call graph data."
puts "================================"
#exec ../bin/tclsh ../common/corepanel_test2.tcl corepanel.dat "C:/mdg/ble_mesh/List" 
exec ../bin/tclsh ../common/corepanel_test2.tcl corepanel.dat [lindex $argv 1] 

puts "Generate simplified static call graph data."
puts "==========================================="
#exec ../bin/tclsh ../common/corepanel_test2.tcl corepanel.dat "C:/mdg/ble_mesh/List" s
exec ../bin/tclsh ../common/corepanel_test2.tcl corepanel.dat [lindex $argv 1] s

# custom processing of Main_high_lev.dot
#puts "Generate custom Main_high_lev call graph data."
#puts "=============================================="
#source filter_main_high_lev.tcl
#filter_main_high_lev graphviz/Main_high_lev.dot
#filter_main_high_lev graphviz/Main_high_lev.sim.dot
#exec dot -Tpdf graphviz/Main_high_lev.proc_only.dot -o graphviz/Main_high_lev.proc_only.pdf 
#exec dot -Tpdf graphviz/Main_high_lev.sim.proc_only.dot -o graphviz/Main_high_lev.sim.proc_only.pdf 


