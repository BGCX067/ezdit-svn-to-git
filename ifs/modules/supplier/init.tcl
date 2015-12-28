oo::objdefine $MODULE {
	method author {} {return "dai"}
	method description {} {return ""}
	method name {} {return [::msgcat::mc "Supplier"]}
	method version {} {return "1.0"}	
	
	method init {} {
		my variable Priv
		
		event add <<ButtonL-Click>> <Button-1>
		
		set dir [my pwd]
		
		set f [file join $dir [::msgcat::mclocale].msg]
		if {[file exists $f]} {namespace eval :: [list source -encoding utf-8 $f]}
		
		namespace eval ::dApp::supplier {
			variable Obj
			array set Obj [list]
		}

		source -encoding utf-8 [file join $dir main.tcl]
		set obj [::dApp::supplier new $dir]
	}
	method cleanup {} {
		namespace delete ::dApp::supplier
	}
	
	
}
