package provide imgBox 1.0

namespace eval ::imgBox {
	variable Priv
	array set Priv [list __unknow__ ""]
	variable sn 0
}

proc ::imgBox::add {tok name fpath} {
	variable Priv
	
	if {[info exists Priv($name)] && $Priv($name) != ""} {
		::imgBox::delete $tok $name
	}
	set Priv($name) [image create photo -file $fpath]
	return $Priv($name)
}

proc ::imgBox::delete {tok name} {
	variable Priv

	catch {
		image delete $Priv($name)
		array unset Priv $name
	}
	
	return $Priv($name)
}

proc ::imgBox::destroy {tok} {
	variable Priv
	foreach name [array names Priv] {
		catch {
			image delete $Priv($name)
			array unset Priv $name
		}
	}
	interp alias {} $tok {} {}
	return
}

proc ::imgBox::dispatch {tok args} {
	variable Priv
	set cmd [list ::imgBox::[lindex $args 0] $tok]
	foreach arg [lrange $args 1 end] {lappend cmd $arg}
	return [eval $cmd]	
}

proc ::imgBox::get {tok {name ""}} {
	variable Priv
	if {$name != ""} {
		if {![info exists Priv($name)] && $Priv(__unknow__) != ""} {return $Priv(__unknow__)}
		return $Priv($name)
	}
	return [array names Priv]
}

proc ::imgBox::create {{tok ""}} {
	variable Priv
	variable sn
	incr sn
	if {$tok == ""} {set tok ibox$sn}
	interp alias {} $tok {} ::imgBox::dispatch $tok
	return $tok
}

proc ::imgBox::unknow {tok {fpath ""}} {
	variable Priv
	if {$fpath != ""} {
		return [::imgBox::add $tok __unknow__ $fpath]
	} else {
		return $Priv(__unknow__)
	}
}

