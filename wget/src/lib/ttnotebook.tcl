package provide ttnotebook 1.0
package require treectrl
package require img::png
package require tooltip

namespace eval ::ttnotebook {
	variable Priv
	array set Priv [list list_mentu,var ""]
	variable sn 0
	
	set Priv(font1) [font create -size 10]
	set Priv(font2) [font create \
		-family [font configure $Priv(font1) -family] \
		-size [font configure $Priv(font1) -size] \
		-weight bold]
	
	
	set Priv(image,prev1) [image create photo -format png -data {
	iVBORw0KGgoAAAANSUhEUgAAAAcAAAALCAYAAACzkJeoAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A
	/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGAAAAAd0SU1FB9kBAgcqOVutVNkAAAAidEVYdENv
	bW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVAgb24gYSBNYWOHqHdDAAAAYUlEQVQY032PwQ2AMAwDj6hz
	8GSDTlGxRufoTEh5ZILMwDTlRSWqFP+ss2IHYh2sQK21A7vMoLV2v0ZWACABuPtlZud8P6lqN7Ow
	XEopW845hgCrwBgUBT6v/FUMqWoHeAA0gBuYxWUdogAAAABJRU5ErkJggg==
	}]
	
	set Priv(image,list2) [image create photo -format png -data {
	iVBORw0KGgoAAAANSUhEUgAAAA4AAAALCAYAAABPhbxiAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A
	/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGAAAAAd0SU1FB9kBAgY0KZOZEVUAAAAidEVYdENv
	bW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVAgb24gYSBNYWOHqHdDAAAA9UlEQVQoz52RTYrCQBBGX3V3
	CGTjNngBb5FBNwHxEB7Nc2ThEC/hDVyJOwPpv5pVwkB0Zpi3rKoHH1/J4XDQqqooyxLnHMYYXpFz
	JsbIOI4Mw4Dz3lMUBWVZYq3FOfdSjDESYySEgPce6boOgNPppFVV/SgOw8DxeBQAJyIApJRQVQCm
	2YSqoqqklObdLE4R3onee0IIS7EoCp7PJyGERUE5Z6YuFuJ+v+dyuXC73QBmOecMwHq9pmmaWZTz
	55n/4AT59ajve71erxhjSCmx2Wxw7x7+neajkcfjoff7nbqu2e62Yv4SyxpL27ayWq1o21assXwB
	t2tyVFq0Se0AAAAASUVORK5CYII=
	}]

	set Priv(image,prev2) [image create photo -format png -data {
	iVBORw0KGgoAAAANSUhEUgAAAAcAAAALCAYAAACzkJeoAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A
	/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGAAAAAd0SU1FB9kBAgcvFo0LncUAAAAidEVYdENv
	bW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVAgb24gYSBNYWOHqHdDAAAAX0lEQVQY032PsQ2AMAwEjyhz
	UNIzhmVlj8zm3m1GoGeaUBGJyOG71738b4h1sAIi0oE9zaDWer8mrQBABmitXWZ2zvezu3czC8uT
	qm6llBgCrAJjUBT4vPJXMeTuHeABaJkbXGRlD5UAAAAASUVORK5CYII=
	}]

	set Priv(image,next1) [image create photo -format png -data {
	iVBORw0KGgoAAAANSUhEUgAAAAcAAAALCAYAAACzkJeoAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A
	/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGAAAAAd0SU1FB9kBAgcqHBCpgJ4AAAAidEVYdENv
	bW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVAgb24gYSBNYWOHqHdDAAAAXUlEQVQY02NggAA1BhxALi0t
	7T82BUwwRkNDw010BUzIHHQFTOhGNTQ03Dx+/PgmrJIMDAwMO3fu9N26det/rJKmpqYM3t7ejEy4
	JDCMRZZAkUSXgIOtW7f+x2Y3AM4GG8JFg7aLAAAAAElFTkSuQmCC
	}]

	set Priv(image,cancel1) [image create photo -format png -data {
	iVBORw0KGgoAAAANSUhEUgAAAAkAAAAICAIAAACkr0LiAAAACXBIWXMAAAsSAAALEgHS3X78AAAA
	wklEQVR4nDWPIQqFQBgG/6AIomz2BMIiNqPVIqb1DFbLKnsAiycQs8mTWG0GLVpEMIjFYPheeO9N
	HRgYAtD3vVLqeR4AANq2TdN0nmcCME2T53l1XQNomoaIGGPDMBCA9327rrMsK8sy13U1TYvjeF1X
	wh/OORERUZ7n+74D+LllWTjnjDHDMKSU933/3LZtYRiaphlFkeM4uq4nSTKOI53nKaW0bbuqquM4
	lFLfchAEVJal7/tFUXwfrusSQhCREOIDCYF1H0ui62gAAAAASUVORK5CYII=
	}]
			
	set Priv(image,next2) [image create photo -format png -data {
	iVBORw0KGgoAAAANSUhEUgAAAAcAAAALCAYAAACzkJeoAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A
	/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGAAAAAd0SU1FB9kBAgcuLSUbRaAAAAAidEVYdENv
	bW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVAgb24gYSBNYWOHqHdDAAAAXUlEQVQY02NggAA1BhxAztPT
	8z82BUwwRkZGxk10BUzIHHQFTOhGZWRk3Ny3b985rJIMDAwMq1atMty6det/rJK+vr4M3t7ejEy4
	JDCMRZZAkUSXgIOtW7f+x2Y3AOsQG2vIohTZAAAAAElFTkSuQmCC
	}]
	
	set Priv(image,list1) [image create photo -format png -data {
	iVBORw0KGgoAAAANSUhEUgAAAA4AAAALCAYAAABPhbxiAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A
	/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGAAAAAd0SU1FB9kBAgY1BbhaTPcAAAAidEVYdENv
	bW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVAgb24gYSBNYWOHqHdDAAAA7UlEQVQoz53RsW6DQAzG8b85
	DomBDbGzponEwMzIs/CMDOkLZM3KA7BEWUDiuHMnUKWQtuo32v5Jli1d12mapiRJgjGGKIo4SggB
	7z3LsjDPM7FzDmvtDo0xh9B7j/eedV1xziF93wPQ972mafojnOeZtm0FIBaRfRVVBWCrbVFVVJUQ
	wt7boXMO59xbuPVfoLWWaZpIkuQQLsuCtfYVNk3D7XZjHEeA/bohBACKoqCu6x3K9fPKfxIL8uvQ
	/X7XYRgQEUIIlGVJ/O7h33P6OMnz+dTH40Ge55wvZ4n+spaJDFVVSZZlVFUlJjJ8Ae+HbvcDLhAf
	AAAAAElFTkSuQmCC
	}]
	
	set Priv(image,close1) [image create photo -format png -data {
	iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A
	/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGAAAAAd0SU1FB9kBAwclLX5T+w4AAAAZdEVYdENv
	bW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBXgQ4XAAAAD0lEQVQoz2NgGAWjgDoAAAJMAAGiBBJQAAAA
	AElFTkSuQmCC
	}]	
		
	set Priv(image,close2) [image create photo -format png -data {
	iVBORw0KGgoAAAANSUhEUgAAAAkAAAAICAYAAAArzdW1AAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A
	/wD/oL2nkwAAAAlwSFlzAAALEgAACxIB0t1+/AAAAAd0SU1FB9kBBAsPBbBAXgEAAAAZdEVYdENv
	bW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBXgQ4XAAAA0UlEQVQY01WQIaqEAABEh48iLCtWPYEgi81o
	tYhJz2C1rIsH2OIJxGzyJFabQQxusXuB98P+v58/MGneMDACNI4jTdMA6Nd931MUBeu6SoCWZdHt
	dqNtWwB1XYckHMdhmiZ9msMwcL1eKcsS3/cxDIM0Tdn3/Q8CFAQBkpBEVVUcxyFAX/rRtm2SJMdx
	ZFmWTNOU67rvENDr9VIcx1wuF5IkwfM8TNMkyzLmeX5D9/sd27Z5Pp+c56mmaT6zURShx+NBGIbU
	df3vgjzPkUSe53wDyZqOa1Sea8gAAAAASUVORK5CYII=
	}]

	set Priv(image,cancel2) $Priv(image,cancel1) 
	#set Priv(image,sunken) $Priv(image,list1)
	#set Priv(image,raised) $Priv(image,list2)
}

proc ::ttnotebook::btn1_click {tok x y} {
	variable Priv
	set tree $Priv($tok,tree)

	set ninfo [$tree identify $x $y]

	if {[llength $ninfo] != 6} {return}
	foreach {what item where column type name} $ninfo {}
	if {$name == "eIcon" && [$tree item state get $item "selected"]==1} {
		$tok delete
	}
}

proc ::ttnotebook::btn_middle_click {tok x y} {
	variable Priv
	set tree $Priv($tok,tree)

	set ninfo [$tree identify $x $y]

	if {[llength $ninfo] != 6} {return}
	foreach {what item where column type name} $ninfo {}
	if {$item != "item"} {
		$tok delete $item
	}
}

proc ::ttnotebook::create {wpath args} {
	variable Priv
	variable sn

	array set opts [list \
		-control 1 \
		-cancel 1 \
	]
	array set opts $args

	incr sn
	set tok ::ttnotebook::$sn
	interp alias {} $tok {} ::ttnotebook::dispatch $tok
	
	set nb [ttk::frame $wpath]
	
	set tree [treectrl $nb.tree \
		-orient horizontal \
		-showroot no \
		-showline no \
		-selectmod single \
		-showrootbutton no \
		-showbuttons no \
		-showheader no \
		-highlightthickness 0 \
		-relief groove \
		-borderwidth 0 \
		-height 30]

	$tree column create -tag colHead

	if {$opts(-cancel) == 1} {
		$tree element create eIcon image \
			-image [list $Priv(image,close2) {selected} $Priv(image,close1) {}]
	} else {
		$tree element create eIcon image
	}
	$tree element create eTitle text -justify center \
		-lines 1 \
		-fill [list "#000000" {selected} "#888888" {}] \
		-font [list $Priv(font2) {selected} $Priv(font1) {}]
	$tree element create eRect rect \
		-outlinewidth 1  \
		-outline [list "#505050" {selected} "#808080" {}] -open s

	$tree style create styPage
	$tree style elements styPage {eRect eTitle eIcon}
	$tree style layout styPage eTitle -iexpand news -ipadx 10 -ipady 7 -pady {4 2}
	$tree style layout styPage eIcon -visible [list 1 {selected} 0 {}] -ipadx 5 -expand ns -pady {4 2}
	$tree style layout styPage eRect -union {eTitle eIcon} -padx 1
#	$tree style layout styPage ePad -padx 3
	
	$tree notify bind $tree <Selection> [list ::ttnotebook::selection_set $tok %S]
	
	bind $tree <Button-1> [list ::ttnotebook::btn1_click $tok %x %y]
	bind $tree <<ClosePage>> [list ::ttnotebook::btn_middle_click $tok %x %y]
	
	set lblPrev [ttk::label $nb.prev -image $Priv(image,prev1) -state disabled -anchor center]
	set lblCurr [ttk::label $nb.curr -textvariable ::ttnotebook::Priv($tok,curr) -state disabled -anchor center]
	set lblNext [ttk::label $nb.next -image $Priv(image,next1) -state disabled -anchor center]
	set lblList [ttk::label $nb.list -image $Priv(image,list1) -state disabled -anchor center]
	
	bind $lblNext <ButtonRelease-1> [list ::ttnotebook::cmd_next $tok]
	bind $lblPrev <ButtonRelease-1> [list ::ttnotebook::cmd_prev $tok]
	bind $lblList <ButtonRelease-1> [list ::ttnotebook::list_menu_popup $tok %X %Y]
	
	foreach {item name} [list $lblNext next $lblPrev prev $lblList list] {
		bind $item <ButtonPress-1> +[list %W configure -image $Priv(image,${name}2)]
		bind $item <ButtonRelease-1> +[list %W configure -image $Priv(image,${name}1)]
		bind $item <Enter> [list %W configure -relief groove]
		bind $item <Leave> [list %W configure -relief flat]		
	}
	
	::tooltip::tooltip $lblList [::msgcat::mc "List All Pages"]
	::tooltip::tooltip $lblNext [::msgcat::mc "Next Page"]
	::tooltip::tooltip $lblPrev [::msgcat::mc "Previous Page"]
	
	set body [ttk::frame $nb.body -height 100]
	
	
	grid $tree -row 0 -column 0 -sticky "news"
	if {$opts(-control) == 1} {
		grid $lblPrev -row 0 -column 1 -sticky "news" -ipadx 2 -padx 1
		grid $lblCurr -row 0 -column 2 -sticky "news" -padx 2
		grid $lblNext -row 0 -column 3 -sticky "news" -ipadx 2 -padx 1
		grid $lblList -row 0 -column 4 -sticky "news" -ipadx 2  -padx 2
	}
	grid $body -row 1 -column 0 -columnspan 5 -sticky "news" -ipadx 2 -ipady 2
	grid rowconfigure $nb 1 -weight 1 
	grid columnconfigure $nb 0 -weight 1
	
	set Priv($tok,frame) $wpath
	set Priv($tok,tree) $tree
	set Priv($tok,body) $body
	set Priv($tok,event,PageChanged) ""
	set Priv($tok,event,CountChanged) ""
	set Priv($tok,event,BeforeDelete) ""
	set Priv($tok,curr) 0
	set Priv($tok,prev) 0
	set Priv($tok,pages) 0
	set Priv($tok,lblNext) $lblNext
	set Priv($tok,lblPrev) $lblPrev
	set Priv($tok,lblList) $lblList
	set Priv($tok,lblCurr) $lblCurr
	
	$tree configure -background [. cget -background]
	
	return $tok
}

proc ::ttnotebook::dispatch {tok args} {
	variable Priv
	set cmd [list ::ttnotebook::cmd_[lindex $args 0] $tok]
	foreach arg [lrange $args 1 end] {lappend cmd $arg}
	return [eval $cmd]	
}


proc ::ttnotebook::image_get {name} {
	variable Priv
	return $Priv(image,$name)
}

proc ::ttnotebook::image_names {} {
	variable Priv
	set ret ""
	foreach {key val} [array get Priv image,*] {
		lassign [split $key ","] name img
		lappend ret $img
	}
	return [lsort $ret]
}

proc ::ttnotebook::image_set {name img} {
	variable Priv
	set Priv(image,$name) $img
}

proc ::ttnotebook::list_menu_popup {tok X Y} {
	variable Priv
	set tree $Priv($tok,tree)
	set m $tree.list_menu
	if {[winfo exists $m]} {destroy $m}
	menu $m -tearoff 0
	set Priv(list_mentu,var) [$tree selection get]
	foreach item [$tree item children 0] {
		set title [$tree item element cget $item 0 eTitle -text]
		$m add radiobutton \
			-label $title \
			-variable ::ttnotebook::Priv(list_mentu,var) \
			-value $item \
			-command "$tree selection clear ; $tree selection add $item"
	}
	
	tk_popup $m $X $Y
	
}

proc ::ttnotebook::selection_set {tok item} {
	variable Priv
	
	if {$item == ""} {::ttnotebook::pos_update $tok ; return}

	set tree $Priv($tok,tree)
	set body $Priv($tok,body)
	
	set win [pack slaves $body]
	if {[winfo exists $win]} {pack forget $win}
	
	set win [$tree item element cget $item 0 eTitle -data]
	if {[winfo exists $win]} {pack $win -expand 1 -fill both -in $body}

	$tree see $item
	
	::ttnotebook::pos_update $tok
	
	focus [pack slaves $body]
	
	return
}

proc ::ttnotebook::scroll_next {tok} {
	variable Priv
	set tree $Priv($tok,tree)
	$tree xview scroll 1 pages
	return
}

proc ::ttnotebook::scroll_prev {tok} {
	variable Priv
	set tree $Priv($tok,tree)
	$tree xview scroll -1 pages
	return
}

proc ::ttnotebook::pos_update {tok} {
	variable Priv
	
	set tree $Priv($tok,tree)
	set body $Priv($tok,body)
	
	set pages [$tree item children 0]
	if {$pages == ""} {
		$Priv($tok,lblNext) configure -state disabled
		$Priv($tok,lblCurr) configure -state disabled
		$Priv($tok,lblPrev) configure -state disabled
		$Priv($tok,lblList) configure -state disabled
		set Priv($tok,curr) "0/0"
		set Priv($tok,pages) 0
		foreach cmd $Priv($tok,event,PageChanged) {eval [lappend cmd ""]}
		return
	}
	$Priv($tok,lblNext) configure -state normal
	$Priv($tok,lblCurr) configure -state normal
	$Priv($tok,lblPrev) configure -state normal
	$Priv($tok,lblList) configure -state normal	

	
	set item [$tree selection get]
	if {$item == ""} {
		set Priv($tok,curr) 0/[llength $pages]
		set Priv($tok,pages) [llength $pages]
		foreach cmd $Priv($tok,event,PageChanged) {eval [lappend cmd ""]}
		return
	}
	
	set idx [expr [lsearch $pages $item] +1]
	set Priv($tok,curr) $idx/[llength $pages]
	set Priv($tok,pages) [llength $pages]
	
	if {$Priv($tok,curr) != $Priv($tok,prev)} {
		foreach cmd $Priv($tok,event,PageChanged) {eval [lappend cmd $item]}
	}
	set Priv($tok,prev) $Priv($tok,curr) 
	return
}

############################# 
# 
#############################

proc ::ttnotebook::cmd_add {tok win title {icons ""}} {
	variable Priv
	set tree $Priv($tok,tree)
	
	set item [$tree item create -button no -parent 0]
	$tree item style set $item 0 styPage
	$tree item lastchild 0 $item
	$tree item element configure $item 0 eTitle -text $title -data $win
	
	if {$icons != ""} {
		lassign $icons i1 i2
		$tree item element configure $item 0 eIcon  -image [list $i1 {selected} $i2 {}]	
	}
	
	foreach cmd $Priv($tok,event,CountChanged) {eval [lappend cmd [llength [$tree item children 0]]]}
	
	$tree selection clear
	$tree selection add $item
#	::ttnotebook::selection_set $tok $item
	return $item
}

proc ::ttnotebook::cmd_bind {tok tag script} {
	variable Priv

	set e [string range $tag 1 end-1]
	if {[string index $script 0] == "+"} {
		set script [string range $script 1 end]
		lappend Priv($tok,event,$e) $script	
	} else {
		set Priv($tok,event,$e) [list $script]
	}	
}

proc ::ttnotebook::cmd_count {tok} {
	variable Priv
	set tree $Priv($tok,tree)
	return [llength [$tree item children 0]]
}


proc ::ttnotebook::cmd_delete {tok {item ""}} {
	variable Priv
	set tree $Priv($tok,tree)

	
	if {$item == ""} {set item [$tree selection get]}
	if {$item == "" || [$tree item id $item] == ""} {return 0}

	set next [$tree item nextsibling $item]
	if {$next == ""} {set next [$tree item prevsibling $item]}
	foreach cmd $Priv($tok,event,BeforeDelete) {if {![eval [lappend cmd $item]]} {return 0}}
	set win [$tree item element cget $item 0 eTitle -data]
	if {[winfo exists $win]} {destroy $win}

	$tree item delete $item

	if {$next == ""} {
		::ttnotebook::pos_update $tok
		foreach cmd $Priv($tok,event,CountChanged) {eval [lappend cmd 0]}
		return 1
	}

	foreach cmd $Priv($tok,event,CountChanged) {eval [lappend cmd [llength [$tree item children 0]]]}
	$tree selection clear
	$tree selection add $next
	return 1
}

proc ::ttnotebook::cmd_delete_all {tok} {
	variable Priv
	set tree $Priv($tok,tree)
	set items [$tree item children 0]
	foreach item $items {
		set win [$tree item element cget $item 0 eTitle -data]
		foreach cmd $Priv($tok,event,BeforeDelete) {if {![eval [lappend cmd $item]]} {return}}
		if {[winfo exists $win]} {destroy $win}

		$tree item delete $item
	}
	::ttnotebook::pos_update $tok
	foreach cmd $Priv($tok,event,CountChanged) {eval [lappend cmd [llength [$tree item children 0]]]}
	return
}

proc ::ttnotebook::cmd_destroy {tok} {
   variable Priv
  	set tree $Priv($tok,tree)
	::ttnotebook::cmd_delete_all

   interp alias {} $tok {} {}
   array unset Priv $tok,*
}

proc ::ttnotebook::cmd_frame {tok} {
	variable Priv
	return $Priv($tok,frame)	
}

proc ::ttnotebook::menu_popup {tok} {
	variable Priv
	
	set tree $Priv($tok,tree)	
	set btn $Priv($tok,btnList)
	
	lassign [winfo pointerxy $btn] x y

	if {[winfo exists $btn.popupMenu]} {destroy $btn.popupMenu}
	set m [menu $btn.popupMenu -tearoff 0]
	
	set Priv($tok,btnList,var) [$tree select get]
	foreach tid [$tree item children 0] {
		set name [$tree item element cget $item 0 eTitle -text]
		$m add radiobutton \
			-value $tid \
			-variable ::ttnotebook::Priv($tok,btnList,var) \
			-label $name \
			-command [list $tok select $tid]
	}	
	
	tk_popup $m $x $y
}

proc ::ttnotebook::cmd_next {tok} {
	variable Priv
	set tree $Priv($tok,tree)
	
	set item [$tree selection get]
	
	set pages [$tree item children 0]
	set idx [lsearch $pages $item]
	if {$idx == -1} {return}
	if {$idx == [llength $pages] -1 } {return}
	
	set next [lindex $pages [incr idx]]
	$tree selection clear
	$tree selection add $next
	return
}

proc ::ttnotebook::cmd_pages {tok} {
	variable Priv
	set tree $Priv($tok,tree)
	return [$tree item children 0]
}

proc ::ttnotebook::cmd_prev {tok} {
	variable Priv
	set tree $Priv($tok,tree)
	
	set item [$tree selection get]
	
	set pages [$tree item children 0]
	set idx [lsearch $pages $item]
	if {$idx <= 0} {return}
	
	set prev [lindex $pages [incr idx -1]]
	$tree selection clear
	$tree selection add $prev
	return
}

proc ::ttnotebook::cmd_select {tok {item ""}} {
	variable Priv
	set tree $Priv($tok,tree)
	if {$item == ""} {return [$tree selection get]}
	$tree selection clear
	$tree selection add $item
	return 
}

proc ::ttnotebook::cmd_title_get {tok item} {
	variable Priv
	set tree $Priv($tok,tree)
	if {$item == ""} {return}
	return [$tree item element cget $item 0 eTitle -text]	
}

proc ::ttnotebook::cmd_title_set {tok item title} {
	variable Priv
	set tree $Priv($tok,tree)
	$tree item element configure $item 0 eTitle -text $title
	return $item
}




