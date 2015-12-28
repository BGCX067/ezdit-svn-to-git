package require TclOO
package provide ::ddb::validator 1.0

oo::class create ::ddb::validator {
	constructor {args} {
		my variable Priv
		
		array set Priv $args
	}
	
	destructor {
		my variable Priv
		
		array unset Priv
	}
	
	method date {start end flag val} {
		set val [split $val "."]
		if {[llength $val] != 3} {return 0}
		lassign $val y m d
		set y [string trimleft $y "0"]
		set m [string trimleft $m "0"]
		set d [string trimleft $d "0"]
		
		lassign [split $start "."] y1 m1 d1
		lassign [split $end "."] y2 m2 d2
		if {![my int 0 9999 $y] || ![my int 1 12 $m] || ![my int 1 31 $d]} {return 0}
		if {$flag} {incr y 1911}
		if {$y < $y1 || $y > $y2} {return 0}
		
		set str $y
		if {$m > 10} {
			append str $m
		} else {
			append str 0 $m
		}
		append str 01
		
		set days [clock format [clock scan "$str +1 months -1 days"] -format "%d"]
		
		if {$d > $days} {return 0}
		return 1
	}	
	
	method double {min max val} {
		set val [string map {, ""} $val]
		if {$val == ""} {return 0}
		set val [string trimleft $val "0"]
		if {$val == ""} {set val "0"}
		if {![string is double $val]} {return 0}
		if {$val < $min || $val > $max} {return 0}
		return 1
	}

	method int {min max val} {
		set val [string map {, ""} $val]
		if {$val == ""} {return 0}
		set val [string trimleft $val "0"]
		if {$val == ""} {set val "0"}
		if {![string is integer $val]} {return 0}
		if {$val < $min || $val > $max} {return 0}
		return 1
	}
		
	method string {minlen maxlen chars val} {
		set len [string length $val]
		if {$len < $minlen || $len > $maxlen} {return 0}
		if {$chars != ""} {
			for {set i 0} {$i < $len} {incr i} {
				if {[string first [string index $val $i] $chars] == -1} {return 0}
			}
		}
		return 1
	}
	
}

