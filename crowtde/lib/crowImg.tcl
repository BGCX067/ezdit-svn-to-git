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

package provide crowImg 1.0
package require tkpng

namespace eval ::crowImg {
	variable images
	array set images ""
}

proc ::crowImg::init {dpath} {
	set flist [lsort -dictionary [glob -nocomplain -directory $dpath -types {f} -- *.*]]
	foreach f $flist {
		catch {set ::crowImg::images([file rootname [file tail $f]]) [image create photo -file $f]}
	}
}

proc ::crowImg::load_image {fname} {
	set imgName [file rootname [file tail $fname]]
	if {[info exists ::crowImg::images($imgName)]} {return $::crowImg::images($imgName)}
	if {[catch {set ::crowImg::images($imgName) [image create photo -file $fname]}]} {
		return $::crowImg::images(unknow)
	}
	return $::crowImg::images($imgName)
}

proc ::crowImg::get_image {imgName} {
	if {[info exists ::crowImg::images($imgName)]} {return $::crowImg::images($imgName)}
	return $::crowImg::images(unknow)
}

