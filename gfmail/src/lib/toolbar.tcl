package provide toolbar 1.0
##################################################################################
# Copyright (C) 2006-2007 Tai, Yuan-Liang                                        #
#                                                                                #
# This program is free software; you can redistribute it and/or modify           #
# it under the terms of the GNU General Public License as published by           #
# the Free Software Foundation; either version 2 of the License, or              #
# (at your option) any later version.                                            #
#                                                                                #
# This program is distributed in the hope that it will be useful,                #
# but WITHOUT ANY WARRANTY; without even the implied warranty of                 #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                  #
# GNU General Public License for more details.                                   #
#                                                                                #
# You should have received a copy of the GNU General Public License              #
# along with this program; if not, write to the Free Software                    #
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA   #
##################################################################################
#
#	set tbar [::toolbar::toolbar $path]
#	$tbar add button -text "" -image "" -command {} -tooltip {}
#	$tbar add separator
#	$tbar destroy
#
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

	set widget [::ttk::button $Priv($tok,path).widget$Priv(sn)]

	foreach {key value} $args	{
		switch -exact -- $key {
			-tooltip {::tooltip::tooltip $widget $value}
			default {$widget configure $key $value}
		}
	}

	pack $widget -side left -fill y -padx 2 -pady 4 
	return $widget
}

proc ::toolbar::add_checkbutton {tok args} {
	variable Priv
	
	incr Priv(sn)

	set widget [::ttk::checkbutton $Priv($tok,path).widget$Priv(sn)]

	foreach {key value} $args	{
		switch -exact -- $key {
			-tooltip {::tooltip::tooltip $widget $value}
			default {$widget configure $key $value}
		}
	}

	pack $widget -side left -fill y -padx 2 -pady 4 
	return $widget
}

proc ::toolbar::add_combobox {tok args} {
	variable Priv
	
	incr Priv(sn)

	set widget [::ttk::combobox $Priv($tok,path).widget$Priv(sn)]

	foreach {key value} $args	{
		switch -exact -- $key {
			-tooltip {::tooltip::tooltip $widget $value}
			default {$widget configure $key $value}
		}
	}

	pack $widget -side left -fill y -padx 2 -pady 4 
	return $widget
}

proc ::toolbar::add_entry {tok args} {
	variable Priv
	
	incr Priv(sn)

	set widget [::ttk::entry $Priv($tok,path).widget$Priv(sn)]

	foreach {key value} $args	{
		switch -exact -- $key {
			-tooltip {::tooltip::tooltip $widget $value}
			default {$widget configure $key $value}
		}
	}

	pack $widget -side left -fill y -padx 2 -pady 4 
	return $widget
}

proc ::toolbar::add_label {tok args} {
	variable Priv
	
	incr Priv(sn)

	set widget [::ttk::label $Priv($tok,path).widget$Priv(sn)]

	foreach {key value} $args	{
		switch -exact -- $key {
			-tooltip {::tooltip::tooltip $widget $value}
			default {$widget configure $key $value}
		}
	}

	pack $widget -side left -fill y -padx 2 -pady 4 
	return $widget
}

proc ::toolbar::add_separator {tok args} {
	variable Priv
	
	incr Priv(sn)	
	set sep [::ttk::separator $Priv($tok,path).sep$Priv(sn) -orient v]

	foreach {key value} $args	{
		switch -exact -- $key {
			-tooltip {::tooltip::tooltip $btn $value}
			default {$sep configure $key $value}
		}
	}

	pack $sep -side left -fill y -padx 5 -pady 5
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
	
	::ttk::label $Priv($tok,path) -relief groove
	::ttk::label $Priv($tok,path).sep$Priv(sn) -relief groove
	pack $Priv($tok,path).sep$Priv(sn) -side left -fill y -padx 4 -pady 3
	
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
