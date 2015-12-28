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
#	$tbar create button -text "" -image "" -command {} -tooltip {}
#	$tbar create separator
#	$tbar destroy
#
package require tile
package require tooltip

namespace eval ::toolbar {
	variable PRIV
	array set PRIV [list sn 0]
	
	::ttk::style layout Toolbar.TButton {
		border -children {
			padding -children {
				label
			}
		}
	}
	::ttk::style configure Toolbar.TButton -borderwidth 1 -padding 4
	::ttk::style map Toolbar.TButton -relief {
		pressed sunken
		active raised
	}
	
}

proc ::toolbar::add {tok args} {
	variable PRIV
	set cmd [list ::toolbar::add_[lindex $args 0] $tok]
	foreach arg [lrange $args 1 end] {lappend cmd $arg}
	return [eval $cmd]	
}

proc ::toolbar::add_button {tok args} {
	variable PRIV
	
	incr PRIV(sn)

	set widget [::ttk::button $PRIV($tok,path).widget$PRIV(sn) -style Toolbutton]

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
	variable PRIV
	
	incr PRIV(sn)

	set widget [::ttk::checkbutton $PRIV($tok,path).widget$PRIV(sn)]

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
	variable PRIV
	
	incr PRIV(sn)

	set widget [::ttk::combobox $PRIV($tok,path).widget$PRIV(sn)]

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
	variable PRIV
	
	incr PRIV(sn)

	set widget [::ttk::entry $PRIV($tok,path).widget$PRIV(sn)]

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
	variable PRIV
	
	incr PRIV(sn)

	set widget [::ttk::label $PRIV($tok,path).widget$PRIV(sn)]

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
	variable PRIV
	
	incr PRIV(sn)	
	set sep [::ttk::separator $PRIV($tok,path).sep$PRIV(sn) -orient v]

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
	variable PRIV
	destroy $PRIV($tok,path)
	array unset PRIV $tok,*
	interp alias {} $tok {} {}
	return
}

proc ::toolbar::dispatch {tok args} {
	variable PRIV
	set cmd [list ::toolbar::[lindex $args 0] $tok]
	foreach arg [lrange $args 1 end] {lappend cmd $arg}
	return [eval $cmd]	
}

proc ::toolbar::frame {tok} {
	variable PRIV
	return $PRIV($tok,path)
}

proc ::toolbar::init {tok} {
	variable PRIV
	
	incr PRIV(sn)
	
	::ttk::frame $PRIV($tok,path) -relief groove
	::ttk::label $PRIV($tok,path).sep$PRIV(sn) -relief groove
	pack $PRIV($tok,path).sep$PRIV(sn) -side left -fill y -padx 4 -pady 3
	
	return $tok
}

proc ::toolbar::toolbar {path args} {
	variable PRIV
	incr PRIV(sn)
	
	set tok toolbar:$PRIV(sn)

	interp alias {} $tok {} ::toolbar::dispatch $tok
	set PRIV($tok,path) $path
		
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
