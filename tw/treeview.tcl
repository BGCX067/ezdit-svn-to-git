package provide ::tw::treeview  $::tw::OPTS(version)

::oo::class create ::tw::treeview {
	constructor {wpath args} {
		my variable PRIV OPTS

		# -scrollbar : vertical (v) , horizontal (h) , both (b)
		array set OPTS [list \
			-scrollbar "both" \
			-autoscroll 1 \
		]
		array set OPTS $args

		array set PRIV [list \
			frame $wpath \
			treeview "" \
			vscrollbar "" \
			hscrollbar ""
		]

		my _frame_init
	}

	destructor {
		my variable PRIV OPTS
		if {[winfo exists $PRIV(frame)]} {destroy $PRIV(frame)}
		array unset PRIV
		array unset OPTS
	}

	method frame {args} {
		my variable PRIV OPTS
		if {[llength $args] == 0} {return $PRIV(frame)}
		return [$PRIV(frame) {*}$args]
	}

	method hscrollbar {args} {
		my variable PRIV
		if {[llength $args] == 0} {return $PRIV(hscrollbar)}
		return [$PRIV(hscrollbar) {*}$args]
	}

	method treeview {args} {
		my variable PRIV
		if {[llength $args] == 0} {return $PRIV(treeview)}
		return [$PRIV(treeview) {*}$args]
	}

	method vscrollbar {args} {
		my variable PRIV
		if {[llength $args] == 0} {return $PRIV(vscrollbar)}
		return [$PRIV(vscrollbar) {*}$args]
	}

	method _frame_init {} {
		my variable PRIV OPTS

		foreach opt [list -scrollbar -autoscroll] {
			set varname [string range $opt 1 end]
			set $varname $OPTS($opt)
			unset OPTS($opt)
		}

		set fme [ttk::frame $PRIV(frame)]
		set tv [ttk::treeview $fme.tv {*}[array get OPTS]]

		set vs [ttk::scrollbar $fme.vs -command [list $tv yview] -orient vertical]
		set hs [ttk::scrollbar $fme.hs -command [list $tv xview] -orient horizontal]
		$tv configure -xscrollcommand [list $hs set] -yscrollcommand [list $vs set]
		if {$autoscroll && [namespace exists ::autoscroll]} {
			::autoscroll::autoscroll $vs
			::autoscroll::autoscroll $hs
		}
		set scrollbar [string index $scrollbar 0]
		grid $tv -column 0 -row 0 -sticky news
		if {$scrollbar == "v"  || $scrollbar == "b" } {grid $vs -column 1 -row 0 -sticky news	}
		if {$scrollbar == "h" || $scrollbar == "b"} {	grid $hs -row 1 -column 0 -columnspan 2 -sticky news}
		grid columnconfigure $fme 0 -weight 1
		grid rowconfigure $fme 0 -weight 1
		set PRIV(hscrollbar) $hs
		set PRIV(vscrollbar) $vs
		set PRIV(treeview) $tv
	}

}
