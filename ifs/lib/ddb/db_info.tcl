package require TclOO
package provide ::ddb::dbInfo 1.0

oo::class create ::ddb::dbInfo {
	constructor {args} {
		my variable Priv
		
		array set Priv [list \
			-type "sqlite" \
			-host "localhost" \
			-port "0" \
			-user "" \
			-password "" \
			-dbfile "" \
		]
		
		array set Priv $args
	}
	
	destructor {
		my variable Priv
		
		array unset Priv
	}
	
	method get {{key ""}} {
		my variable Priv
		
		if {$key == ""} {return [array get Priv]}
		
		if {![info exists Priv($key)]} {return}
		
		return $Priv($key)
	}
	
	method set {key val} {
		my variable Priv
		
		set Priv($key) $val
	}
	
}
