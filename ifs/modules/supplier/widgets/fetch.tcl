oo::class create ::dApp::supplier::fetch {
	constructor {wpath args} {
		my variable Priv
		
		set Priv(opts,buttonCursor) "hand2"
		set Priv(win,frame) $wpath
		my Ui_Init
	}
	
	destructor {}
	
	method check_all {state} {
		my variable Priv
		set tv $Priv(obj,tv)	
		set db $::dApp::supplier::Obj(db)
		
		$db check "" $state
		
		$Priv(obj,tv) sbar_find
	}
	
	method fetch_email {} {
		my variable Priv
		
		set db $::dApp::supplier::Obj(db)
		set tv $Priv(obj,tv)
		
		set ids [$db checks]
		
		if {[llength $ids] == 0} {
			tk_messageBox \
				-title [::msgcat::mc "提示"] \
				-message [::msgcat::mc "請先選取想要提取的記錄。"] \
				-icon info \
				-type ok
			return
		}
		
		set filter "_CHECK_ == 'CHECK'"
		set mails ""
		foreach {name email} [$db query $filter -fields {name email}] {
			if {[string trim $email] == ""} {continue}
			append mails "\"$name\" <$email>,"
		}
		set mails [string trimright $mails ","]
		
		$Priv(win,txt) delete 1.0 end
		$Priv(win,txt) insert end $mails
		
	}

	method text_clear {} {
		my variable Priv
		set tv $Priv(obj,tv)	
		
		$Priv(win,txt) delete 1.0 end
	}
	
	method text_copy {} {
		my variable Priv
		set tv $Priv(obj,tv)	
		
		$Priv(win,txt) tag delete sel
		$Priv(win,txt) tag add sel 1.0 end
		tk_textCopy $Priv(win,txt)
		after idle [list focus $Priv(win,txt)]
	}	
	
	method tv {args} {
		my variable Priv
		$Priv(obj,tv) {*}$args
	}
	
	method Ui_Init {} {
		my variable Priv
		
		set ibox $::dApp::supplier::Obj(ibox)
		set wpath $Priv(win,frame)
		#
		#   fme : frame
		# 	-win : panedwindow
		#		-fme1	: frame
		#			-tbar : frame
		#			-sep  : separator
		#			-tv	 : tableview
		#		-fme2 : frame
		#			-title : label
		#			-txt   : text
		
		set fme [ttk::frame $wpath -borderwidth 2 -relief groove]
		set win [ttk::panedwindow $fme.win -orient vertical]
		pack $win -expand 1 -fill both
		
		set fme1 [ttk::frame $win.fme1]
		set fme2 [ttk::frame $win.fme2]
		$win add $fme1 -weight 1
		$win add $fme2 -weight 1
		
		#################### tbar sep tv #####################
		set tbar [ttk::frame $fme1.tbar]
		
		set Priv(obj,tv) [::dApp::supplier::tableview new $fme1.tv \
			-showsbar 1 \
			-showctrl 1 \
			-showfilter 0 \
		]
		
		set lblPos [ttk::label $tbar.lblPos \
			-text [::msgcat::mc "供應商模組 > 提取E-Mail"] \
			-style Position.TLabel \
		]
		pack $lblPos -fill y -padx 6 -pady 2 -side left		
		pack [ttk::separator $tbar.sep1 -orient vertical] -fill y -padx 6 -pady 2 -side left								
		
		set btnFetchMail [ttk::button $tbar.btnFetchMail \
			-text [::msgcat::mc "提取E-Mail"] \
			-image [$ibox get mail] \
			-compound left \
			-command [list [self object] fetch_email] \
			-style Toolbutton \
		]
		pack $btnFetchMail -side left -padx 6 -pady 2
		
		set btnCheckAll [ttk::button $tbar.btnCheckAll \
			-text [::msgcat::mc "選擇所有的項目"] \
			-image [$ibox get check_all] \
			-compound left \
			-command [list [self object] check_all "CHECK"] \
			-style Toolbutton \
		]		
		pack $btnCheckAll -side left -padx 6 -pady 2		
		
		set btnClearAll [ttk::button $tbar.btnClearAll \
			-text [::msgcat::mc "取消選擇的項目"] \
			-image [$ibox get uncheck_all] \
			-compound left \
			-command [list [self object] check_all "!CHECK"] \
			-style Toolbutton \
		]		
		pack $btnClearAll -side left -padx 6 -pady 2
		
		pack $tbar -fill x -side top 
		pack [ttk::separator $fme1.sep -orient horizontal] -fill x
		pack [$Priv(obj,tv) frame] -expand 1 -fill both		

		bind $wpath <Visibility> [list $Priv(obj,tv) sbar_find]		
		
		pack [$Priv(obj,tv) sbar_filter_init $tbar.ctrl] -side right -padx 6 -pady 2
		##################### title txt ######################
		set tbar [ttk::frame $fme2.tbar]
		set btnCopy [ttk::button $tbar.btnCopy \
			-text [::msgcat::mc "複製清單內容"] \
			-command [list [self object] text_copy] \
			-image [$ibox get copy] \
			-compound left \
			-style Toolbutton \
		]
		set btnClear [ttk::button $tbar.btnClear \
			-text [::msgcat::mc "清除清單內容"] \
			-command [list [self object] text_clear] \
			-image [$ibox get cancel] \
			-compound left \
			-style Toolbutton \
		]		
		pack $btnCopy $btnClear -side left -padx 3
		
		
		set txt [text $fme2.txt -relief groove]

		set vs [ttk::scrollbar $fme2.vs -command [list $txt yview] -orient vertical]
		set hs [ttk::scrollbar $fme2.hs -command [list $txt xview] -orient horizontal]
		$txt configure -xscrollcommand [list $hs set] -yscrollcommand [list $vs set]
		::autoscroll::autoscroll $vs
		::autoscroll::autoscroll $hs
		
		grid [ttk::separator $fme2.sep] - -sticky we
		grid $tbar - -sticky nw -pady 3 -padx 5
		grid $txt $vs -sticky "news"
		grid $hs - -sticky "we"
		grid rowconfigure $fme2 2 -weight 1
		grid columnconfigure $fme2 0 -weight 1
		
		$txt tag configure sel -background "#e4e5e6" -foreground black -relief groove -borderwidth 2
		
		set Priv(win,txt) $txt
		
		
		
	}
}
