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

package provide crowTemplate 1.0
package require tdom

namespace eval ::crowTemplate {
	variable templPath ""
}
proc ::crowTemplate::init {templDir} {
	variable templPath
	set templPath $templDir
}

proc ::crowTemplate::item_eval {templ fpath} {
	
	set fd [open [file join $templ init.xml] r]
	set data [read $fd]
	close $fd
	set doc [dom parse $data]
	set root [$doc documentElement]
	
	array set arrInfo [list templPath $templ namespace	""	init "" main "" cleanup "" descript "" name "" image ""]
	set nodeTemplate [$root selectNodes "/Template"]
#	set arrInfo(name) [$nodeTemplate getAttribute "name"]
#	set arrInfo(image) [$nodeTemplate getAttribute "image"]
	set arrInfo(namespace) [[$nodeTemplate selectNodes "Namespace"] text]
	set arrInfo(init) [[$nodeTemplate selectNodes "Init"] text]
#	set arrInfo(description) [[$nodeTemplate selectNodes "Description"] text]
	$doc delete
	catch {
		source [file join $templ init.tcl]
		$arrInfo(init) $fpath
		namespace delete $arrInfo(namespace)
	}
	array unset arrInfo
	return
}

proc ::crowTemplate::item_ls {} {
	variable templPath
	set ret ""
	set templs [glob -nocomplain -directory [file join $templPath "item"] -type {d} *]

	foreach templ [lsort $templs] {
		set fd [open [file join $templ init.xml] r]
		set data [read $fd]
		close $fd
		set doc [dom parse $data]
		set root [$doc documentElement]
		
		array set arrInfo [list path $templ namespace	""	init "" main "" cleanup "" descript "" name "" image ""]
		set nodeTemplate [$root selectNodes "/Template"]
		set arrInfo(name) [$nodeTemplate getAttribute "name"]
		set arrInfo(image) [$nodeTemplate getAttribute "image"]
		set arrInfo(namespace) [[$nodeTemplate selectNodes "Namespace"] text]
		set arrInfo(name) [namespace eval ::crowTemplate [list ::msgcat::mc $arrInfo(name)] ]
#		set arrInfo(init) [[$nodeTemplate selectNodes "Init"] text]
#		set arrInfo(description) [[$nodeTemplate selectNodes "Description"] text]
		
		::crowImg::load_image [file join $templ $arrInfo(image)]
		set arrInfo(image) [file rootname [file tail $arrInfo(image)]]
		lappend ret [array get arrInfo]
		array unset arrInfo
		$doc delete	
	}

	return $ret
}

proc ::crowTemplate::project_ls {} {
	variable templPath
	set templs [glob -nocomplain -directory [file join $templPath "project"] -type {d} *]
	set ret ""
	foreach templ [lsort $templs] {
		set fd [open [file join $templ init.xml] r]
		set data [read $fd]
		close $fd
		set doc [dom parse $data]
		set root [$doc documentElement]
		
		array set arrInfo [list path $templ namespace	""	init "" main "" cleanup "" descript "" name "" image "" mainScript "" interpreter ""]
		set nodeTemplate [$root selectNodes "/Template"]
		set arrInfo(name) [$nodeTemplate getAttribute "name"]
		set arrInfo(image) [$nodeTemplate getAttribute "image"]
		set arrInfo(mainScript) [$nodeTemplate getAttribute "mainScript"]
		set arrInfo(interpreter) [$nodeTemplate getAttribute "interpreter"]
	
		set arrInfo(namespace) [[$nodeTemplate selectNodes "Namespace"] text]
		set arrInfo(init) [[$nodeTemplate selectNodes "Init"] text]
		set arrInfo(description) [[$nodeTemplate selectNodes "Description"] text]
		set arrInfo(description) [namespace eval ::crowTemplate [list ::msgcat::mc $arrInfo(description)] ]
		
		::crowImg::load_image [file join $templ $arrInfo(image)]
		set arrInfo(image) [file rootname [file tail $arrInfo(image)]]
		lappend ret [array get arrInfo]
		
		array unset arrInfo
		$doc delete	
	}
	return $ret
}
