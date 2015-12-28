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

namespace eval ::frmAbout {
}

proc ::frmAbout::show {path} {
	catch {destroy $path}
	set win [toplevel $path]
	set lblImg [label $win.lblImg -image [::crowImg::get_image crow] ]
	set lblTitle [label $win.lblTitle -text "CrowTDE 0.5" -font [font create -size 20 -weight bold -family "helvetica"]]
	set lblMsg [label $win.lblMsg -font [::crowFont::get_font smaller] \
		-text [::msgcat::mc "CrowTDE is an open source Tcl/Tk development %s environment written in Tcl/Tk. Its purposes is to provide a %s convenient environment for Tcl/Tk programmers." "\n" "\n"]]
	set lblAuth [label $win.lblAuth -text [::msgcat::mc "Copyright (C) 2006-2007 Tai, Yuan-Liang & Zheng, Shao-Huan"] \
		-font [::crowFont::get_font smallest]]
	set lblVisit [label $win.lblVisit -text [::msgcat::mc "Visit : http://crow.ee.stut.edu.tw/dai/crowtde/"] \
		-font [::crowFont::get_font smaller]]

	set others "
Nagelfar
   Copyright (c) 1999-2006, Peter Spjuth  (peter.spjuth@space.se)
   http://nagelfar.berlios.de/

Enhanced Tk Console: tkcon
   Copyright (c) 1995-2004, Jeffrey Hobbs (jeff.hobbs@acm.org)
   http://tkcon.sourceforge.net/
"
	
	set lblOthers [label $win.lblOthers -text [string trimleft $others] -font [::crowFont::get_font smaller] -bd 2 -relief sunken -justify left -anchor w]	
	
	set fmeBtn [frame $win.fmeBtn]
	set btnCredits [button $fmeBtn.btnCredits -text [::msgcat::mc "Credits"] -width 8 -command {::frmAbout::show_credits}]
	set btnLicense [button $fmeBtn.btnLicense -text [::msgcat::mc "License"] -width 8 -command {::frmAbout::show_license}]
	set btnExit [button $fmeBtn.btnExit -text [::msgcat::mc "Exit"] -width 8 -command [list destroy $win]]
	pack $btnCredits $btnLicense $btnExit -expand 1 -pady 5 -side left
	pack $lblImg $lblTitle $lblMsg $lblAuth $lblVisit $lblOthers -side top -fill x -pady 5
	pack $fmeBtn -side top -fill x -pady 10

	update
	set geometry [split [lindex [split [wm geometry $path] "+"] 0] "x"]
	set w [lindex $geometry end-1]
	set h [lindex $geometry end]
	set x [expr {([winfo screenwidth .]/2 - $w/2)}]
	set y [expr {([winfo screenheight .]/2 - $h/2)}]
	wm geometry $path +$x+$y
	wm title $path [::msgcat::mc "About CrowTDE"]
	wm resizable $path 0 0
	return $path
}

proc ::frmAbout::show_credits {} {
	catch {destroy .frmAbout_about_credits}
	set win [toplevel .frmAbout_about_credits]
	set nb [NoteBook $win.nb]
	$nb insert end "translate" -text [::msgcat::mc "Translators"]
	set fmeTranslate [$nb getframe "translate"]

	set sw [ScrolledWindow $fmeTranslate.sw -bd 1 -relief sunken ]
	set txt [text $fmeTranslate.txt -bd 1 -relief ridge -highlightthickness 0 ]
	
	$sw setwidget $txt
	$txt insert end [::msgcat::mc "German - Michael Schlenker <mic42@user.sourceforge.net> %s" "\n"]
	$txt insert end [::msgcat::mc "Italian - Diego <siarodx@gmail.com> %s" "\n"]
	$txt insert end [::msgcat::mc "Traditional Chinese - Zang, Ke-Yuan <jarry@crow.ee.stut.edu.tw> %s" "\n"]
	$txt configure -state disabled
	pack $sw -expand 1 -fill both
	
	
	set btn [button $win.btn -text [::msgcat::mc "Exit"] -width 6 -command [list destroy $win]]
	
	$nb raise "translate"
	pack $nb -expand 1 -fill both -side top -padx 2 -pady 3
	pack $btn -side top -padx 2 -pady 3 -fill x
	
	
	update
	set geometry [split [lindex [split [wm geometry $win] "+"] 0] "x"]
	set w [lindex $geometry end-1]
	set h [lindex $geometry end]
	set x [expr {([winfo screenwidth .]/2 - $w/2)}]
	set y [expr {([winfo screenheight .]/2 - $h/2)}]
	wm geometry $win +$x+$y
	wm title $win [::msgcat::mc "Credits"]
	wm resizable $win 0 0	
}

proc ::frmAbout::show_license {} {
	catch {destroy .frmAbout_about_license}
	set win [toplevel .frmAbout_about_license]
	set lbl [label $win.lbl -text [::msgcat::mc "License:"] -anchor w -justify left]
	set txt [text $win.txt -bd 1 -relief ridge -highlightthickness 0 ]
	set btn [button $win.btn -text [::msgcat::mc "Exit"] -width 6 -command [list destroy $win]]
	
	$txt insert end \
"This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by  
the Free Software Foundation; either version 2 of the License, or (at your option) any later version.  

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.  

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA."

	pack $lbl -side top -padx 2 -expand 1 -fill x -pady 2
	pack $txt -side top -padx 2 -pady 2 -expand 1 -fill both
	pack $btn -side top -padx 2 -fill x
	
	update
	set geometry [split [lindex [split [wm geometry $win] "+"] 0] "x"]
	set w [lindex $geometry end-1]
	set h [lindex $geometry end]
	set x [expr {([winfo screenwidth .]/2 - $w/2)}]
	set y [expr {([winfo screenheight .]/2 - $h/2)}]
	wm geometry $win +$x+$y
	wm title $win [::msgcat::mc "CrowTDE License"]
	wm resizable $win 0 0	
}


