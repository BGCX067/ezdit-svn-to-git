oo::class create ::dApp:dbAdjuster {
	superclass ::ddb::sqlite
	constructor {} {
		my variable Priv
		
		set Priv(dbfile) [file join $::dApp::Env(appPath) db]
		set flag 0
		if {![file exists $Priv(dbfile)]} {set flag 1}
		next $Priv(dbfile)
		if {$flag} {my init}
	}
	
	destructor {
		my variable Priv
		next
	}
	
	method param_add {key val} {
		my variable Priv
		return [my insert system key $key value $val]
	}		
	
	method param_get {key} {
		my variable Priv
		return [my query system "key == '$key'" -fields value]
	}
	
	method param_set {key val} {
		my variable Priv
		return [my update system "key == '$key'" value $val]
	}	
	
	method init {} {
		my create system {
			key text,
			value text
		}
	}
}


