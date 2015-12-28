package provide imgBox 1.0
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

namespace eval ::imgBox {
	variable PRIV
	array set PRIV [list __unknow__ ""]
	variable sn 0
}

proc ::imgBox::add {tok name fpath} {
	variable PRIV
	
	if {[info exists PRIV($name)] && $PRIV($name) != ""} {
		::imgBox::delete $tok $name
	}
	set PRIV($name) [image create photo $name -file $fpath]

	return $PRIV($name)
}

proc ::imgBox::delete {tok name} {
	variable PRIV

	catch {
		image delete $PRIV($name)
		array unset PRIV $name
	}
	
	return $PRIV($name)
}

proc ::imgBox::destroy {tok} {
	variable PRIV
	foreach name [array names PRIV] {
		catch {
			image delete $PRIV($name)
			array unset PRIV $name
		}
	}
	interp alias {} $tok {} {}
	return
}

proc ::imgBox::dispatch {tok args} {
	variable PRIV
	set cmd [list ::imgBox::[lindex $args 0] $tok]
	foreach arg [lrange $args 1 end] {lappend cmd $arg}
	return [eval $cmd]	
}

proc ::imgBox::get {tok {name ""}} {
	variable PRIV
	if {$name != ""} {
		if {![info exists PRIV($name)] && $PRIV(__unknow__) != ""} {return $PRIV(__unknow__)}
		return $PRIV($name)
	}
	return [array names PRIV]
}

proc ::imgBox::create {{tok ""}} {
	variable PRIV
	variable sn
	incr sn
	if {$tok == ""} {set tok imgBox:$sn}
	interp alias {} $tok {} ::imgBox::dispatch $tok
	return $tok
}

proc ::imgBox::unknow {tok {fpath ""}} {
	variable PRIV
	if {$fpath != ""} {
		return [::imgBox::add $tok __unknow__ $fpath]
	} else {
		return $PRIV(__unknow__)
	}
}

