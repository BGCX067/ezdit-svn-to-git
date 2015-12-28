oo::class create ::dApp::supplier::tableview {
	superclass ::ddb::tableview
	
	constructor {wpath args} {
		my variable Priv
		next $wpath {*}$args
		
		set Priv(db) $::dApp::supplier::Obj(db)
	}
	
	destructor {}


	method count {filter} {
		my variable Priv
		
		return [$Priv(db) count $filter]
	}

	method refresh {filter} {
		my variable Priv

		set db $Priv(db)
		my item_clear
		set ret [$db query $filter -command [list [self object] item_add]]
		
		return $ret
	}
	
	method row_check_click {items state} {
		my variable Priv
		
		set tree $Priv(win,tree)

		foreach item $items {
			lappend ids [$tree item element cget $item id text -text]
			$tree item state set $item $state
		}

		$Priv(db) check $ids $state
	}
	
	method row_delete_click {items {force 0}} {
		my variable Priv
		
		set tree $Priv(win,tree)
		if {$force == 0} {
			set ans [tk_messageBox \
				-title [::msgcat::mc "刪除"] \
				-message [::msgcat::mc "確定要刪除這筆記錄嗎?"] \
				-icon question \
				-type yesno \
			]
			if {$ans != "yes"} {return}
		}
		

		foreach item $items {
			lappend ids [$tree item element cget $item id text -text]
			
			my item_delete $item
		}
		$Priv(db) delete $ids
		
		my sbar_find
	}
	method row_edit_click {item} {
		puts $item
	}	
}
