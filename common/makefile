TCL = tclsh
target:
	$(TCL) $(SCDS_HOME)/scds_gen_test.tcl config.dat $(MDG_HOME) MDG_HOME
	make -C $(MDG_HOME)/dat
	make -C $(MDG_HOME)/gencode/simple
	make -C $(MDG_HOME)/gencode/complex

clean :
	make -C $(MDG_HOME)/dat clean
	make -C $(MDG_HOME)/gencode/simple clean
	make -C $(MDG_HOME)/gencode/complex clean
	$(TCL) $(SCDS_HOME)/scds_gen_test.tcl clean $(MDG_HOME)
