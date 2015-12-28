package provide ::tw::rc $::tw::OPTS(version)

::oo::class create ::tw::rc {
	constructor {rcfile {autoFlush 1}} {
		# SYNOPSIS :  rc new
		my variable PRIV rc mode

		array set PRIV [list]
		set rc $rcfile
		set mode $autoFlush
		my Load
	}

	destructor {
		my variable PRIV rc mode
		
		array unset PRIV
		unset rc
		unset mode
	}
	
	method append {name args} {
		# SYNOPSIS :  rc append name val1 val2 ...
		# RETURN : val
		my variable PRIV rc mode
		
		lappend PRIV($name) {*}$args
		if {$mode} {my flush}
		return $PRIV($name)
	}
	
	method delete {args} {
		# SYNOPSIS :  rc delete name1 name2 ...
		my variable PRIV rc mode
		
		foreach name $args {array unset PRIV $name}
		if {$mode} {my flush}
		return
	}
	
	method exists {name} {
		# SYNOPSIS :  exists name
		# RETURN : 1 -> exists , 0 -> not exists
		my variable PRIV
		
		if {[info exists PRIV($name)]} {return 1}
		return 0
	}
	
	method file {} {
		# SYNOPSIS :  file
		# RETURN : rcfile
		my variable PRIV rc
		
		return $rc
	}
	
	method flush {} {
		my Save
	}
	
	method get {name} {
		my variable PRIV

		if {[info exists PRIV($name)]} {return $PRIV($name)}
		return ""
	}
	
	method names {} {
		# SYNOPSIS : rc names
		# RETURN : all rc name	
		my variable PRIV
		return [array names PRIV]
	}
	
	method set {name val} {
		# SYNOPSIS : rc set name val
		# RETURN : val		
		my variable PRIV rc mode
		
		set PRIV($name) [list $val]
		if {$mode} {my Save}
		return $PRIV($name)
	}
	
	method Load {} {
		my variable PRIV rc
		
		if {![file isfile $rc]} {return}
		set fd [open $rc r]
		set name ""
		while {![eof $fd]} {
			gets $fd data
			if {[string trim $data] == ""} {continue}
			set type [string index $data 0]
			set data [string range $data 1 end]
			if {$type == "+"} {
				set name $data
				continue
			}
			if {$type == "-"} {
				lappend PRIV($name) $data
				continue
			}
		}
		close $fd		
	}
	
	method Save {} {
		my variable PRIV rc
		
		if {$rc == ""} {return}
		
		set fd [open $rc w]
		foreach {name} [lsort [array names PRIV]] {
			set val $PRIV($name)
			puts $fd +$name
			foreach {item} $val {puts $fd -$item}
		}
		close $fd
	}
}




