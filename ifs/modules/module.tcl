oo::class create ::dApp::module {
	constructor {dir} {
		my variable Priv
		array set Priv [list \
			STATE 0 \
			PWD $dir \
			NAME [file tail $dir] \
		]
		
		set f [file join $dir [::msgcat::mclocale].msg]
		if {[file exists $f]} {
			namespace eval :: [list source -encoding utf-8 $f]
		}
		
	}
	destructor {my variable Priv ; array unset Priv	}
	method state {} {my variable Priv ; return $Priv(STATE)}
	method toggle {} {
		my variable Priv
		if {$Priv(STATE) == 1} {
			my cleanup
			set Priv(STATE) 0
		} else {
			my init
			set Priv(STATE) 1
		}
	}
	
	method pwd {} {my variable Priv ; return $Priv(PWD)}
	method name {} {my variable Priv ; return $Priv(NAME)}
	method author {} {return ""}
	method icon {} {return [$::dApp::Obj(ibox) get module]}
	method version {} {return ""}
	method description {} {return ""}

	method init {} {}
	method cleanup {} {}
}




