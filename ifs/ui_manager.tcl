oo::class create ::dApp:uiManager {
	constructor {} {
		my variable Priv CloseCmd
		
		array set CloseCmd ""
		
		set Priv(sn) 0
		
		my Ui_Init
				
		if {[$::dApp::Obj(db) param_get "uimgr.selected"] == ""} {
			$::dApp::Obj(db) param_add "uimgr.selected" "home"
		}

	}
	
	destructor {
		my variable Priv
	}
	
	method tab {cmd args} {
		return [my tab_$cmd {*}$args]
	}
	
	method tab_add {win args} {
		my variable Priv CloseCmd
		
		set nb $Priv(win,nb) 
		if {[lsearch -exact [$Priv(win,nb) tabs] $win] > 0} {
			return [$nb select $win]
		}
		
		array set opts [list \
			-image [$::dApp::Obj(ibox) get page] \
			-compound left \
			-padding 7 \
			-closecmd "" \
		]
		
		array set opts $args
		set closecmd $opts(-closecmd)
		unset opts(-closecmd)
		
		$nb insert end $win {*}[array get opts]
		set CloseCmd($win) $closecmd
		return [$nb select $win]
		
	}
	
	method tab_close {{tab ""}} {
		my variable Priv CloseCmd
		
		set nb $Priv(win,nb)
		
		if {$tab == ""} {set tab [$nb select]}
		
		if {$tab == $Priv(win,homeFrame)} {return}
		if {$CloseCmd($tab) == ""} {
			$nb forget $tab
			return
		}
		if {![eval $CloseCmd($tab)]} {return}
		$nb forget $tab
	}
	
	method tab_last {} {
		my variable Priv
		my tab_select [$::dApp::Obj(db) param_get "uimgr.selected"]
	}
	
	method tab_select {win} {
		my variable Priv
		
		set nb $Priv(win,nb)
		
		if {$win == "home"} {set win $Priv(win,homeFrame)}
		if {![winfo exists $win]} {return}
		
		if {[lsearch -exact [$nb tabs] $win] >= 0} {
			return [$nb select $win]
		}
		
		return		
	}
	
	method widget {cmd args} {
		return [my widget_$cmd {*}$args]
	}
	
	method widget_create {args} {
		my variable Priv
		
		set tree $Priv(win,home)
		
		incr Priv(sn)
		set fme [ttk::frame $tree.wdg$Priv(sn)]		
		
		set item [$tree item create -button no]
		$tree item lastchild 0 $item
		$tree item element configure $item col win -window $fme		
		
		return $fme
	}	
	
	
	method Home_Init {} {
		my variable Priv
		
		set fme [ttk::frame $Priv(win,nb).fmeHome ]
		set Priv(win,homeFrame) $fme
		
		set tree [treectrl $fme.tree \
			-height 300 \
			-width 300 \
			-showroot no \
			-showline no \
			-selectmod signle \
			-showrootbutton no \
			-showbuttons no \
			-showheader no \
			-scrollmargin 16 \
			-highlightthickness 0 \
			-relief groove \
			-bg white \
			-bd 0 \
			-usetheme 1 \
			-xscrolldelay "500 50" \
			-yscrolldelay "500 50"]
		
		set Priv(win,home) $tree

		set vs [ttk::scrollbar $fme.vs -command [list $Priv(win,home) yview] -orient vertical]
		set hs [ttk::scrollbar $fme.hs -command [list $Priv(win,home) xview] -orient horizontal]
		$Priv(win,home) configure -yscrollcommand [list $vs set] -xscrollcommand [list $hs set]
		
		::autoscroll::autoscroll $vs
		::autoscroll::autoscroll $hs
		
		grid $Priv(win,home) $vs -sticky "news"
		#grid $hs - -sticky "news"
		grid rowconfigure $fme 0 -weight 1
		grid columnconfigure $fme 0 -weight 1			
		
		my tab add $fme \
			-padding {7 7 7 7} \
			-text "Home" \
			-image [$::dApp::Obj(ibox) get home]
			
		$tree element create rect  rect  -fill "#9b9b9b" -outline "#555555" -outlinewidth 1
		$tree element create win window
		
		$tree style create body
		$tree style elements body [list rect win]
		$tree style layout body win -sticky news  -iexpand news -minheight  150
		$tree style layout body rect -union {win} -iexpand news		-padx 30 -pady {30 0} -ipadx 1 -ipady 1
		
		$tree column create -tags col -itemstyle body	
		
		bind $tree <Configure> {
			set tree %W
			set w [expr [winfo width $tree] - 60]
			if {$w > 0} {$tree style layout body win -width $w}
		}
	}
	
	method Tab_Changed {} {
		my variable Priv
		
		set nb $Priv(win,nb)
		set tab [$nb select]
		set state "normal"
		if {$tab == $Priv(win,homeFrame)} {set state "disabled"}
		
		$::dApp::Obj(db) param_set "uimgr.selected"  $tab
		$Priv(win,btnR) configure -state $state		
	}
	
	method Tab_Close {x y} {
		my variable Priv
		
		set nb $Priv(win,nb)
		set tab [$nb index "@$x,$y"]
		set win [$nb select]
		if {$tab == 0} {return}
		
		if {[$nb index $win] == $tab} {my tab_close $win}
	}
	
	method Ui_Init {} {
		my variable Priv
		
		set wpath ".nb"
		set nb [ttk::notebook $wpath -style Heading.TNotebook]
		pack $nb -expand 1 -fill both -padx 2 -pady 2
		set Priv(win,nb) $nb
		
		set Priv(win,btnL) [ttk::button $nb.btnLeft \
			-style Start.Heading.Toolbutton \
		]
		
		set Priv(win,btnR) [ttk::button $nb.btnRight \
			-style Close.Heading.Toolbutton \
			-command [list [self object] tab_close] \
		]		
		
		set Priv(win,lblTitle) [ttk::label .title -text "進銷存管理系統" \
			-anchor e \
			-justify right \
			-foreground "#757575" \
			-font [font create -family "微軟正黑體" -size 22 -weight bold] \
		]
		
		place .title -relwidth 0.48 -relx 0.5

	
		my Ui_[string totitle $::dApp::Env(os)]_Init
		
		bind $nb <<NotebookTabChanged>> [list [self object] Tab_Changed]
		
		bind $nb <<ButtonM-Click>> [list [self object] Tab_Close %x %y]
		
		my Home_Init
	}
	
	method Ui_Darwin_Init {} {
		my variable Priv
		
		place $Priv(win,btnL) -x 22 -y 26
		place $Priv(win,btnR) -relx 1 -x -45 -y 37
	}
	
	method Ui_Linux_Init {} {
		my variable Priv
		place $Priv(win,btnL) -x 7 -y 29
		place $Priv(win,btnR) -relx 1 -x -26 -y 39
	}
	
	method Ui_Windows_Init {} {
		my variable Priv
		place $Priv(win,btnL) -x 7 -y 30
		place $Priv(win,btnR) -relx 1 -x -26 -y 42
	}
	
	method Test {} {
		my tab add [ttk::frame .nb.l2] -text "CRM" -image [$::dApp::Obj(ibox) get client] 
		
		set fme [my widget_create]
		
		set fmeIcon [ttk::frame $fme.fmeIcon ]
		set fmeFun [ttk::frame $fme.fmeFun ]
		place $fmeIcon -width 100 -relheight 1
		place $fmeFun -relwidth 1 -width -100 -x 100 -relheight 1 -anchor nw
				
		set lblIcon [ttk::button $fmeIcon.lblIcon \
			-image [$::dApp::Obj(ibox) get client] \
			-text "客戶管理模組" \
			-compound top]
		
		pack $lblIcon -expand 1 -fill both -padx 7 -pady 7 -anchor center

		
		ttk::button $fmeFun.btn1 \
			-image [$::dApp::Obj(ibox) get add] \
			-compound left \
			-text "增加一筆新的資料" \
			-style Toolbutton
		ttk::button $fmeFun.btn2 \
			-compound left \
			-image [$::dApp::Obj(ibox) get delete] \
			-text "由目前的資料庫中刪除除料" \
			-style Toolbutton
			
		ttk::button $fmeFun.btn3 \
			-compound left \
			-image [$::dApp::Obj(ibox) get export] \
			-text "輸出常用的報表資訊" \
			-style Toolbutton			
	
		pack $fmeFun.btn1 $fmeFun.btn2 $fmeFun.btn3 -side top -padx 10 -anchor nw -pady 5		
		
		#my widget create 
	}
	export Tab_Changed Tab_Close
}
