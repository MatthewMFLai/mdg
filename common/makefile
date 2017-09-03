corepanel : bySymbol.tcl \
     bySymbolDefined.tcl byGlobal_Sym_Link.tcl byModule_Link.tcl \
     byModule_Property.tcl byRequired_Sym_Link.tcl malloc.tcl \
     bySym_Property.tcl byCorepanel_Module.tcl bySymbol_Depend.tcl

malloc.tcl : $(UTIL_HOME)/malloc.tcl
	cp $(UTIL_HOME)/malloc.tcl . 

bySymbol.tcl : $(PATTERN_HOME)/symbol.tcl
	$(PATTERN_HOME)/genPattern.tcl $(PATTERN_HOME)/symbol bySymbol

bySymbolDefined.tcl : $(PATTERN_HOME)/symboldefined.tcl
	$(PATTERN_HOME)/genPattern.tcl $(PATTERN_HOME)/symboldefined bySymbolDefined

byGlobal_Sym_Link.tcl : $(PATTERN_HOME)/lattice.tcl
	$(PATTERN_HOME)/genPattern.tcl $(PATTERN_HOME)/lattice byGlobal_Sym_Link

byModule_Link.tcl : $(PATTERN_HOME)/graph.tcl
	$(PATTERN_HOME)/genPattern.tcl $(PATTERN_HOME)/graph byModule_Link

byModule_Property.tcl : $(PATTERN_HOME)/assoc.tcl
	$(PATTERN_HOME)/genPattern.tcl $(PATTERN_HOME)/assoc byModule_Property

byRequired_Sym_Link.tcl : $(PATTERN_HOME)/assoc.tcl
	$(PATTERN_HOME)/genPattern.tcl $(PATTERN_HOME)/assoc byRequired_Sym_Link

bySym_Property.tcl : $(PATTERN_HOME)/assoc.tcl
	$(PATTERN_HOME)/genPattern.tcl $(PATTERN_HOME)/assoc bySym_Property

byCorepanel_Module.tcl : $(PATTERN_HOME)/assoc.tcl
	$(PATTERN_HOME)/genPattern.tcl $(PATTERN_HOME)/assoc byCorepanel_Module

bySymbol_Depend.tcl : $(PATTERN_HOME)/graph.tcl
	$(PATTERN_HOME)/genPattern.tcl $(PATTERN_HOME)/graph bySymbol_Depend

#release : corepanel
#	tar cvfX /tmp/corepanel_runtime.tar exclude *

clean :
	rm bySymbol.tcl \
        bySymbolDefined.tcl byGlobal_Sym_Link.tcl byModule_Link.tcl \
        byModule_Property.tcl byRequired_Sym_Link.tcl malloc.tcl \
        bySym_Property.tcl byCorepanel_Module.tcl bySymbol_Depend.tcl
