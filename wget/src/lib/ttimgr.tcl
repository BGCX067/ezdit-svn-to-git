package provide ttimgr 1.0

namespace eval ::ttimgr {
	variable Priv
	array set Priv [list]
	variable sn 0
	

	set Priv(__unknow__) [image create photo -format png -data {
	iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A
	/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGAAAAAd0SU1FB9kBEA4WLl5MDHoAAAAZdEVYdENv
	bW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBXgQ4XAAAAEklEQVQ4y2NgGAWjYBSMAggAAAQQAAGFP6py
	AAAAAElFTkSuQmCC
	}]	
	
}

proc ::ttimgr::add {tok name fpath} {
	variable Priv
	
	if {[info exists Priv($name)] && $Priv($name) != ""} {
		::ttimgr::delete $tok $name
	}
	set Priv($name) [image create photo -file $fpath]
	return $Priv($name)
}

proc ::ttimgr::delete {tok name} {
	variable Priv

	catch {
		image delete $Priv($name)
		array unset Priv $name
	}
	
	return
}

proc ::ttimgr::destroy {tok} {
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

proc ::ttimgr::dispatch {tok args} {
	variable Priv
	set cmd [list ::ttimgr::[lindex $args 0] $tok]
	foreach arg [lrange $args 1 end] {lappend cmd $arg}
	return [eval $cmd]	
}

proc ::ttimgr::get {tok {name ""}} {
	variable Priv
	if {$name != ""} {
		if {![info exists Priv($name)] && $Priv(__unknow__) != ""} {return $Priv(__unknow__)}
		return $Priv($name)
	}
	return [array names Priv]
}

proc ::ttimgr::create {{tok ""}} {
	variable Priv
	variable sn
	incr sn
	if {$tok == ""} {set tok ibox$sn}
	interp alias {} $tok {} ::ttimgr::dispatch $tok
	return $tok
}

proc ::ttimgr::exists {tok name} {
	variable Priv
	if {[info exists Priv($name)]} {return 1}
	return 0
}

proc ::ttimgr::unknow {tok {fpath ""}} {
	variable Priv
	if {$fpath != ""} {
		return [::ttimgr::add $tok __unknow__ $fpath]
	} else {
		return $Priv(__unknow__)
	}
}




