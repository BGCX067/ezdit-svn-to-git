namespace eval ::body {
	variable Priv
	array set Priv [list]
	
}
 
proc ::body::init {wpath} {
	variable Priv
	
	ttk::frame $wpath
	
	set fmeV [ttk::panedwindow $wpath.fmeV]
	
	set lrframe [ttk::panedwindow $fmeV.lrframe -orient horizontal]
	
	$fmeV add $lrframe -weight 1
	$fmeV add [::body::bframe_init $fmeV.bframe]
	
	$lrframe add [::body::lframe_init $lrframe.lframe]
	$lrframe add [::body::rframe_init $lrframe.rframe] -weight 1

	pack $fmeV -expand 1 -fill both -pady 5 -padx 3
	
	set ::dApp::Priv(win,panetb) $fmeV
	set ::dApp::Priv(win,panelr) $lrframe
	set ::dApp::Priv(win,paner) $lrframe.rframe
	set ::dApp::Priv(win,panel) $lrframe.lframe
	
	return $wpath
}

proc ::body::bframe_init {wpath} {
	
	set ibox $::dApp::Priv(ibox)
	
	set bframe [::ttk::notebook $wpath]
	
	source -encoding utf-8  [file join $::dApp::Priv(appPath) output.tcl]
	
	set output [::output::init $wpath.output]
	$bframe add $output \
		-text [::msgcat::mc "訊息"] \
		-compound left \
		-image [$ibox get output]			
	
	set ::dApp::Priv(win,output) $output
	
	return $bframe
}

proc ::body::lframe_init {wpath} {
	variable Priv
	
	set ibox $::dApp::Priv(ibox)
	
	set nb [::ttk::notebook $wpath]
	
	source -encoding utf-8   [file join $::dApp::Priv(appPath) bookmark.tcl]
	
	
	$nb add [::bookmark::init $nb.bookmark] \
		-compound left \
		-text [::msgcat::mc "我的最愛"] \
		-image [$ibox get categorys]
	
	
	return $nb
}

proc ::body::rframe_init {wpath} {
	variable Priv
	
	set ibox $::dApp::Priv(ibox)
	
	set nb [::ttk::notebook $wpath]
	
	source -encoding utf-8   [file join $::dApp::Priv(appPath) abrowser.tcl]
	#source -encoding utf-8   [file join $::dApp::Priv(appPath) vbrowser.tcl]
	
	$nb add [::abrowser::init $nb.abrowser] \
		-compound left \
		-text [::msgcat::mc "相簿清單"] \
		-image [$ibox get album]
#	$nb add [::vbrowser::init $nb.vbrowser] \
#		-compound left \
#		-text [::msgcat::mc "影音清單"] \
#		-image [$ibox get video]	
	
	return $nb
}




