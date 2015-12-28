package require ttdialog
package require http
package require autoscroll

namespace eval ::about {
	variable Priv
	array set Priv [list]
}

proc ::about::show {} {
	variable Priv
	set ibox $::dApp::Priv(ibox)
	set win ._dapp_about
	if {[winfo exists $win]} {
		raise $win
		return
	}
	set win [::ttdialog::dialog $win \
		-title [::msgcat::mc "About %s" $::dApp::Priv(title)] \
		-default "" \
		-buttons "" \
	]
	
	set fontVersion [font create  -weight bold]
	set fontDate [font create ]
	set fontTitle [font create  ]
	set fontName [font create ]
	set fontEmail [font create ]
	
	set fme [::ttdialog::clientframe $win]
	set fmeLeft [ttk::frame $fme.fmeLeft]
	set fmeRight [ttk::frame $fme.fmeRight -padding 20]
	pack $fmeLeft  -side left -expand 0 -fill both
	pack $fmeRight -side left -expand 1 -fill both
	set lblIcon [ttk::label $fmeLeft.lblIcon -compound "left" -image [$ibox get logo] -anchor "center" -anchor s]
	set lblVer [ttk::label $fmeLeft.lblVer -text "$::dApp::Priv(title) v$::dApp::Priv(version)" -anchor "center" -font $fontVersion]
	set lblDate [ttk::label $fmeLeft.lblDate -text "$::dApp::Priv(date)" -anchor "center" -font $fontDate]
	set btnHome [ttk::button $fmeLeft.btnHome \
		-text [::msgcat::mc "Visit"] \
		-command {::dApp::openurl $::dApp::Priv(homePage)}]
	set btnClose [ttk::button $fmeLeft.btnClose -text [::msgcat::mc "Close"] -command [list destroy $win]]
	pack $lblIcon -expand 1 -fill both -side top -padx 30 -pady 10
	pack $lblVer -fill x -side top -pady 6
	pack $lblDate -fill x -side top -pady 1
	pack $btnHome -side top -pady 6 -fill x -padx 15
	pack $btnClose -side top -pady 6 -fill x -padx 15
	
	set txt [text $fmeRight.txt -bd 1 -relief groove -highlightthickness 0 -takefocus 0 -width 45 -height 15]
	set lblCp [ttk::label $fmeRight.lblCp \
		-text [::msgcat::mc "Copyright (C) 2009 Yuan-Liang ,Tai"] \
		-anchor "center" \
		-font $fontDate]
	set vs [ttk::scrollbar $fmeRight.vs -command [list $txt yview] -orient vertical]
	::autoscroll::autoscroll $vs
	$txt configure -yscrollcommand [list $vs set]	
	
	grid $txt $vs -sticky "news"
	grid $lblCp -  -sticky "news"
	grid rowconfigure $fmeRight 0 -weight 1
	grid columnconfigure $fmeRight 0 -weight 1
	
	$txt insert end [::msgcat::mc "Author : %s" $::dApp::Priv(authors)] title
	$txt insert end "\n"
	$txt insert end [::msgcat::mc "Web Site : %s" $::dApp::Priv(homePage)] title
	$txt insert end "\n"
	$txt insert end [::msgcat::mc "E-Mail : %s" $::dApp::Priv(email)] title
	$txt insert end "\n"
	$txt insert end "\n"
	$txt insert end [::msgcat::mc "License Message"]  title

	
#	set fd [open [file join $dApp::Priv(appPath) version.txt] r]
#	chan configure $fd -encoding utf-8
#	$txt insert end [read $fd] name
#	close $fd

	
	$txt tag configure title -font $fontTitle ;#-foreground blue
	$txt tag configure name -font $fontName
	$txt tag configure mail -font $fontEmail ;#-foreground blue
	#$txt configure -state disabled
	
	::ttdialog::dialog_wait $win
	foreach f [list $fontVersion $fontDate $fontTitle $fontName $fontEmail] {
		font delete $f
	}

}
