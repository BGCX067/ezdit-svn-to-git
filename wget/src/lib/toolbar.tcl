package provide toolbar 1.0
namespace eval ::toolbar {
	variable Priv
	array set Priv [list sn 0]
}

proc ::toolbar::add {tok args} {
	variable Priv
	set cmd [list ::toolbar::add_[lindex $args 0] $tok]
	foreach arg [lrange $args 1 end] {lappend cmd $arg}
	return [eval $cmd]	
}

proc ::toolbar::add_button {tok args} {
	variable Priv
	
	incr Priv(sn)
	#-style "Toolbutton"
	set widget [ttk::button $Priv($tok,path).widget$Priv(sn) -style "Toolbutton"]

	foreach {key value} $args	{
		switch -exact -- $key {
			-tooltip {::tooltip::tooltip $widget $value}
			default {$widget configure $key $value}
		}
	}

	pack $widget -side left -pady 2 -padx 1
	return $widget
}

proc ::toolbar::add_checkbutton {tok args} {
	variable Priv
	
	incr Priv(sn)

	set widget [ttk::checkbutton $Priv($tok,path).widget$Priv(sn)]

	foreach {key value} $args	{
		switch -exact -- $key {
			-tooltip {::tooltip::tooltip $widget $value}
			default {$widget configure $key $value}
		}
	}

	pack $widget -side left  -pady 2
	return $widget
}

proc ::toolbar::add_combobox {tok args} {
	variable Priv
	
	incr Priv(sn)

	set widget [ttk::combobox $Priv($tok,path).widget$Priv(sn)]

	foreach {key value} $args	{
		switch -exact -- $key {
			-tooltip {::tooltip::tooltip $widget $value}
			default {$widget configure $key $value}
		}
	}

	pack $widget -side left -pady 2
	return $widget
}

proc ::toolbar::add_entry {tok args} {
	variable Priv
	
	incr Priv(sn)

	set widget [ttk::entry $Priv($tok,path).widget$Priv(sn)]

	foreach {key value} $args	{
		switch -exact -- $key {
			-tooltip {::tooltip::tooltip $widget $value}
			default {$widget configure $key $value}
		}
	}

	pack $widget -side left -pady 2
	return $widget
}

proc ::toolbar::add_label {tok args} {
	variable Priv

	incr Priv(sn)

	set widget [ttk::label $Priv($tok,path).widget$Priv(sn)]

	foreach {key value} $args	{
		switch -exact -- $key {
			-tooltip {::tooltip::tooltip $widget $value}
			default {$widget configure $key $value}
		}
	}

	pack $widget -side left -pady 2
	return $widget
}

proc ::toolbar::add_separator {tok args} {
	variable Priv
	
	incr Priv(sn)	
	set sep [ttk::separator $Priv($tok,path).sep$Priv(sn) -orient v]

	foreach {key value} $args	{
		switch -exact -- $key {
			-tooltip {::tooltip::tooltip $btn $value}
			default {$sep configure $key $value}
		}
	}

	pack $sep -side left -fill y -padx 5 -pady 5
	return $sep
}

proc ::toolbar::add_space {tok args} {
	variable Priv
	
	incr Priv(sn)	
	set sep [ttk::frame $Priv($tok,path).sp$Priv(sn)]

	foreach {key value} $args	{
		switch -exact -- $key {
			-tooltip {::tooltip::tooltip $btn $value}
			default {$sep configure $key $value}
		}
	}

	pack $sep -side left
	return $sep
}

proc ::toolbar::add_space_more {tok args} {
	variable Priv
	
	incr Priv(sn)	
	set sep [ttk::frame $Priv($tok,path).sp$Priv(sn)]

	foreach {key value} $args	{
		switch -exact -- $key {
			-tooltip {::tooltip::tooltip $btn $value}
			default {$sep configure $key $value}
		}
	}

	pack $sep -side left -expand 1 -fill x
	return $sep
}

proc ::toolbar::destroy {tok} {
	variable Priv
	destroy $Priv($tok,path)
	array unset Priv $tok,*
	interp alias {} $tok {} {}
	return
}

proc ::toolbar::dispatch {tok args} {
	variable Priv
	set cmd [list ::toolbar::[lindex $args 0] $tok]
	foreach arg [lrange $args 1 end] {lappend cmd $arg}
	return [eval $cmd]	
}

proc ::toolbar::frame {tok} {
	variable Priv
	return $Priv($tok,path)
}

proc ::toolbar::init {tok} {
	variable Priv
	
	incr Priv(sn)
	
	ttk::frame $Priv($tok,path) -borderwidth 1 -relief groove
	#ttk::label $Priv($tok,path).sep$Priv(sn) -relief groove
	#pack $Priv($tok,path).sep$Priv(sn) -side left -fill y -padx 4 -pady 3
	
	return $tok
}

proc ::toolbar::toolbar {path args} {
	variable Priv
	incr Priv(sn)
	
	set tok toolbar$Priv(sn)

	interp alias {} $tok {} ::toolbar::dispatch $tok
	set Priv($tok,path) $path
		
	::toolbar::init $tok

	foreach {key value} $args	{
		switch -exact -- $key {
			default {$path configure $key $value}
		}
	}

	return $tok
}

#puts [pwd]
#set tbar [::toolbar::toolbar .t -relief groove]
#$tbar add button -text "Hello" -command {exit} -tooltip "dsfsdfa" -image [image create photo -file "./images/computer.png"]
#$tbar add button -text "Hello" -command {puts xxxx} -tooltip "eeee"
#$tbar add label -text "Hello" -tooltip "eeee"
#$tbar add checkbutton -text "Hello" -tooltip "eeee"
#$tbar add combobox -values "1 2 3 4 56"
#$tbar  add separator
#$tbar add button -text "Hello" -command {puts xxxx} -tooltip "eeee"
#pack [$tbar frame] -expand 1 -fill both 






