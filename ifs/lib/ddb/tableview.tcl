package require TclOO
package require msgcat
package require tooltip
package require treectrl
package require autoscroll

package provide ::ddb::tableview 1.0

oo::class create ::ddb::tableview {
	constructor {wpath args} {
		my variable Priv
		
		array set param [list \
			-showsbar 1 \
			-showfilter 1 \
			-showctrl 1 \
			-showcheck 1 \
			-showops 1 \
			-showedit 1 \
			-showdelete 1 \
			-filter "1==1" \
		]
		array set param $args
		
		set Priv(win,frame) $wpath
		set Priv(opts,linkColor) "#004080"
		set Priv(opts,linkMotionColor) "#0066cc"
		set Priv(opts,linkCursor) "hand2"
		set Priv(opts,columnbd) 1
		set Priv(opts,columncolor) "#24108e"
		set Priv(opts,padding) 6
		set Priv(opts,total) 0
		set Priv(opts,pages) 0
		set Priv(opts,currPage) 1
		set Priv(opts,itemsPerPage) 25
		set Priv(opts,orderBy) ""
		set Priv(opts,order) "DESC"
		set Priv(opts,filter) $param(-filter)
		set Priv(opts,showsbar) $param(-showsbar)
		set Priv(opts,showfilter) $param(-showfilter)
		set Priv(opts,showctrl) $param(-showctrl)
		set Priv(opts,showcheck) $param(-showcheck)
		set Priv(opts,showops) $param(-showops)
		set Priv(opts,showedit) $param(-showedit)		
		set Priv(opts,showdelete) $param(-showdelete)		
		
		set Priv(img,check) [image create photo -format png -data {
				iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAuklEQVR42qWScQfFIBTF27dNzIxM
				xtREkpjE7Nu+98q7U+96T0/nj3Vv55wfsYF0akgfpdTj3+KrM1QAKWVzed93DNi2rRmgtcaAdV1/
				lowxBDJpRgAhxNeytTafkEk7AizLkk3nHIEZdlCZQQDOeTa99/lMO8ywg9I9AszznM3jONATwAOl
				DAJM03QHQgj3XN6XPgKM41iFYozk8670EIAx1vgXEHKeJwZQSpsB13VhQHP7rQrQo27AE+MRcBFO
				D9LhAAAAAElFTkSuQmCC
		}]
		
		set Priv(img,uncheck) [image create photo -format png -data {
				iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAiUlEQVR42qXM3QYFIRiF4d3dJpIh
				I5FKJCOSSHe7f9gn4ztZo3Wwzt6HvTbHfhdCeD8Nvw27Ad57OI4xUsA5BwMpJQpYa2Eg50wBYwwM
				lFIocJ4nDFzXRQGtNQzUWilwHAcMtNYooJSCgd47BaSUMDDGoIAQAgbmnBTgnMPAWosCcP3fDdjZ
				NvABvRhVEQglsV8AAAAASUVORK5CYII=
		}]

		set Priv(img,next) [image create photo -format png -data {
			iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0
			U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAEdSURBVDjLY/j//z8DJZiB6gY0rH7xpW7l
			i3YKDHj1v2bli38lix61k2VA5fJn/9eeeP+/fcOL/wlT7/aRbEDegkf/Vxx/93/xobf/S5c8/u/e
			cm0eSQYkTX/4f+HBN/8nbX/xf+bul/8Tp9/9r1N0dgnRBgT33QZqfPW/YdXj/42rH//v2vjkv3fH
			tf9SScceEWWAc8u1/xO2Pv9fsvjB//IlD4CGPPrvXH/5v2Tksc1EGWBaful/+/on/4sW3gfGxsP/
			9lUX/ksEH1gj6rqdhSgDlPPO/q9b8fB/5bIH/23LL/wXD9i7kqRAlEo6+b908f3/NiXn/4t57V1E
			cjRKRB75b1145r+o684FZCUkMb8D/0Uct88euMxEKgYA7Ojrv4CgE7EAAAAASUVORK5CYII=
		}]

		set Priv(img,prev) [image create photo -format png -data {
			iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0
			U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAEXSURBVDjLY/j//z8DJZiBLgZkz37Ynjrz
			4ReyDEideb89afrDf5ET7v4n2YCEqXf7qpY9/T9r76v/Xu03STMgasLteaVLHv+fufvl/6k7X/y3
			qrlCvAHBvTeXFC54ANbctv7p/95Nz/5rFZ0nzoCAzpuPsuc++D91x4v/jasf/y9aeP9/89rH/6VT
			TxJngGPDtc3xU+/879789H/5kgf/02fd+V+17OF/yZhjxBmgVXCaRT3v7BqP1mv/a1Y+/J824/b/
			woX3/osHHSAtECVjjqy0Lb/wP2/+3f+Zs+/8F3XfS3o0inntXWSeffJ/0tRb/0Ucdv4nKyEJW25Z
			YBh/5L+w5fb/ZCdlQYMNs4WMt/wfuMyEDwMA0Irn/pDRT58AAAAASUVORK5CYII=
		}]

		set Priv(img,filter) [image create photo -format png -data {	
			iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0
			U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAIlSURBVDjLY/j//z8DJZiB6gY09895tGTD
			nv+tE+f+B/EnL1gHZofGpt4iyoCK5r5H63YcBmkAG5BRVPO/b/aK/0CDn+A1ICm75H/X9CX/azun
			/m+bNP+/iaUd2AAHN5//WSV1/wuqWsFiVvauyxWUVHkEhUWZwAYsWLOTo6i23aOpbzbYqYXVbf89
			/MP+u3gF/M8pa/gfm5b3PyKn6X/txGX/S1qmgOW4uXmq2NjZGcEGTJi7mmXKwvUPF63b9T+3vAmM
			qyeu+j9l+a7/fUu2/2qcvuF/be/8/9G5zf/DkwvBLmRmYXnAwMDADDYA6FxWkM3TFm/8n11a/x/k
			55Tc8v/RyTn/1bT0wDaCXAITj0svAOpi+AfErGAD0goqWf1CY35a2Dr99wqM+G9sYftfW9/4v6yC
			8lMRMXEDSRm5rWISUv+B/v4vKi75n5eP/z8jI+M7oAFM8ED0CYo6DAq4XYfP/F+15cD/7hnLQAG2
			AiSnqqmzorJlwv+1Ow6B5UAxwscveBglFtx8gv/kVzSDDQC66H98RuF/PWPzqyA5oM1XQTEAMiA1
			v+J/emH1fw5Orj8oBji6+/6HGQBTpKGt/1NRRZ1RQlr2HSjgYAaAwoKVle0/igHWjm7geAYlIJAC
			UGDqGpn9B/qfX0lV4wrIAFAsweSAYYBqACiBGJhYggMP6Of/QJv/S8sq/AcGohTQv7c5ubj/A+Md
			FH2gGABj2mUmUjEAnjJojQ5aPHUAAAAASUVORK5CYII=		
		}]
		
		set Priv(img,up) [image create photo -format png -data {	
			iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABHNCSVQICAgIfAhkiAAAAAlwSFlz
			AAALEgAACxIB0t1+/AAAABx0RVh0U29mdHdhcmUAQWRvYmUgRmlyZXdvcmtzIENTM5jWRgMAAAAV
			dEVYdENyZWF0aW9uIFRpbWUAMi8xNy8wOCCcqlgAAAQRdEVYdFhNTDpjb20uYWRvYmUueG1wADw/
			eHBhY2tldCBiZWdpbj0iICAgIiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+Cjx4Onht
			cG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDQu
			MS1jMDM0IDQ2LjI3Mjk3NiwgU2F0IEphbiAyNyAyMDA3IDIyOjExOjQxICAgICAgICAiPgogICA8
			cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRh
			eC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4
			bWxuczp4YXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iPgogICAgICAgICA8eGFwOkNy
			ZWF0b3JUb29sPkFkb2JlIEZpcmV3b3JrcyBDUzM8L3hhcDpDcmVhdG9yVG9vbD4KICAgICAgICAg
			PHhhcDpDcmVhdGVEYXRlPjIwMDgtMDItMTdUMDI6MzY6NDVaPC94YXA6Q3JlYXRlRGF0ZT4KICAg
			ICAgICAgPHhhcDpNb2RpZnlEYXRlPjIwMDgtMDMtMjRUMTk6MDA6NDJaPC94YXA6TW9kaWZ5RGF0
			ZT4KICAgICAgPC9yZGY6RGVzY3JpcHRpb24+CiAgICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFi
			b3V0PSIiCiAgICAgICAgICAgIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMv
			MS4xLyI+CiAgICAgICAgIDxkYzpmb3JtYXQ+aW1hZ2UvcG5nPC9kYzpmb3JtYXQ+CiAgICAgIDwv
			cmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgogICAgICAgICAgICAg
			ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
			ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAg
			ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
			ICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
			ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIDUdUmQA
			AACoSURBVDiN3ZKxDYMwEEXfRakQ49CzQHaA0Y4dsgC9B7HkyhKi/aliYUKaUCDlJBd3/v/p/GWT
			xJm6nXL/B+C+bcysunR3AYzjaACHgUsqZ2/OOSvnrDdor5d0DHB3pZQUY1SMUSmlAtkDbGs0M9xd
			fd8DsK4rAE3TADDPM8MwVO+sANM0qeu60i/LAkDbtmUWQqggVYjAM4Tw+Eyq1nzd4Je6/iNdD3gB
			mUZ3DbXrQRsAAAAASUVORK5CYII=
		}]
		set Priv(img,down) [image create photo -format png -data {
			iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABHNCSVQICAgIfAhkiAAAAAlwSFlz
			AAALEgAACxIB0t1+/AAAABx0RVh0U29mdHdhcmUAQWRvYmUgRmlyZXdvcmtzIENTM5jWRgMAAAAV
			dEVYdENyZWF0aW9uIFRpbWUAMi8xNy8wOCCcqlgAAAQRdEVYdFhNTDpjb20uYWRvYmUueG1wADw/
			eHBhY2tldCBiZWdpbj0iICAgIiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+Cjx4Onht
			cG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDQu
			MS1jMDM0IDQ2LjI3Mjk3NiwgU2F0IEphbiAyNyAyMDA3IDIyOjExOjQxICAgICAgICAiPgogICA8
			cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRh
			eC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4
			bWxuczp4YXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iPgogICAgICAgICA8eGFwOkNy
			ZWF0b3JUb29sPkFkb2JlIEZpcmV3b3JrcyBDUzM8L3hhcDpDcmVhdG9yVG9vbD4KICAgICAgICAg
			PHhhcDpDcmVhdGVEYXRlPjIwMDgtMDItMTdUMDI6MzY6NDVaPC94YXA6Q3JlYXRlRGF0ZT4KICAg
			ICAgICAgPHhhcDpNb2RpZnlEYXRlPjIwMDgtMDMtMjRUMTk6MDA6NDJaPC94YXA6TW9kaWZ5RGF0
			ZT4KICAgICAgPC9yZGY6RGVzY3JpcHRpb24+CiAgICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFi
			b3V0PSIiCiAgICAgICAgICAgIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMv
			MS4xLyI+CiAgICAgICAgIDxkYzpmb3JtYXQ+aW1hZ2UvcG5nPC9kYzpmb3JtYXQ+CiAgICAgIDwv
			cmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgogICAgICAgICAgICAg
			ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
			ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAg
			ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
			ICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
			ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIDUdUmQA
			AACdSURBVDiN3dKxDYNADIXh36c07MESDEBHJDawR7vb4KSkuwFuCfag41JESCQhJAoFUty5eJ9l
			2VJKYU+5Xen/AE7LJoRwAboPmauqnlcBoOv7fjMdY3wYIMszigje+9K2LQDTNAHg3H3TlBKqKpsA
			gPe+NE3DOI4AVFVFzhkzk+e/WQVmpK5rAIZhwMwE4GtgRoC34Rfglzr+kY4HbthSQqXTR/5kAAAA
			AElFTkSuQmCC			
		}]		
		set Priv(img,none) [image create photo -format png -data {
			iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A
			/wD/oL2nkwAAAAlwSFlzAAALEgAACxIB0t1+/AAAAAd0SU1FB9kLEw4rNJHDCvEAAACYSURBVDjL
			7ZK9CcQwDEafjlTB47j3KMloyijuPYjBlSGkVToTmzSHu+MEKvT3EJ8kZsaMfZi0HwAsz0BEuqKq
			ArDvOwCvgptZ83G41kqttYHGfjN7B6gqpRRyzuScKaU0yAiQ56CIoKqEEAC4rguAdV0BiDGybVu3
			aQc4jgPvfYvP8wTAOddyKaUOsoyapJS+uoL8X3kecANr12hjV5uaYQAAAABJRU5ErkJggg==
		}]
		
		set fonts [font names]
		
		if {[lsearch -exact $fonts TableviewItemFont] < 0} {
			font create TableviewItemFont -size 9 -family "Arial"
			font create TableviewHeaderFont  -size 9 -family "Arial" -weight bold
		}
		
		my Ui_Init
	}
	
	destructor {
		my variable Priv
		array unset Priv
	}
	
	method count {filter} {}
	method refresh {filter} {}
	method row_check_click {items state} {}
	method row_delete_click {items} {}
	method row_edit_click {items} {}	

	method column {cmd args} {
		return [my column_$cmd {*}$args]
	}
	
	method column_add {name args} {
		my variable Priv
		
		set tree $Priv(win,tree)
		
		if {$name == "_CHECK_"} {return}
		
		array set opts [list \
			-font TableviewHeaderFont \
			-borderwidth  $Priv(opts,columnbd) \
			-textcolor $Priv(opts,columncolor) \
			-textpady 3 \
			-arrowgravity right \
		]
		array set opts $args
		
		$tree column create -tags $name {*}[array get opts]
		
		$tree column move _OPERATION_ tail
		
		array unset opts
	}
	
	method column_cget {name args} {
		my variable Priv
		
		set tree $Priv(win,tree)
		
		$tree column cget $name {*}$args
	}	

	method column_click {col} {
		my variable Priv
		
		set tree $Priv(win,tree)
		
		set tag [$tree column cget $col -tags]
		if {$tag == "_CHECK_"} {
			set justify [$tree column cget $col -justify]
			if {$justify == "right"} {
				set state "!CHECK"
				$tree column configure $col -justify left
			} else {
				set state "CHECK"	
				$tree column configure $col -justify right
			}
			
			my row_check_click [$tree item children 0] $state
			
			return
		}
		if {$tag == "_OPERATION_"} {return}
		set arrow [$tree column cget $col -arrow]
		foreach c [$tree column list] {$tree column configure $c -arrow none}
		
		if {$arrow == "none"} {
			$tree column configure $col -arrow up -arrowimage $Priv(img,up)
			set Priv(opts,orderBy) [$tree column cget $col -tags]
			set Priv(opts,order) "ASC"
		}
		if {$arrow == "down"} {
			$tree column configure $col -arrow none 
			set Priv(opts,orderBy) ""
		}
		if {$arrow == "up"} {
			$tree column configure $col -arrow down -arrowimage $Priv(img,down)
			set Priv(opts,order) "DESC"
		}
		
		my sbar_find
	}
	
	method column_configure {name args} {
		my variable Priv
		
		set tree $Priv(win,tree)
		
		$tree column configure $name {*}$args
	}
	
	method column_move {name} {
		my variable Priv
		
		set tree $Priv(win,tree)		
		
		set end [$tree column id _OPERATION_]
		
		$tree column move $name $end
	}
	
	method column_names {} {
		my variable Priv
		
		set tree $Priv(win,tree)
		
		return [$tree column list]
	}
	
	method frame {{fme "frame"}} {
		my variable Priv
		return $Priv(win,$fme)
	}

	method item {cmd args} {
		return [my item_$cmd {*}$args]
	}	
	
	method item_add {args} {
		my variable Priv
		set tree $Priv(win,tree)

		array set opts $args
		if {[info exists opts(_CHECK_)]} {
			set state $opts(_CHECK_)
			unset opts(_CHECK_)
		}
		set item [$tree item create -button no]
		$tree item lastchild 0 $item
		$tree item text $item {*}[array get opts]
		
		if {![info exists state]} {return $item}
		
		if {$state == "CHECK"} {
			$tree item state set $item "CHECK"
		} else {
			$tree item state set $item "!CHECK"
		}
	
		return $item
	}
	
	method item_checks {} {
		my variable Priv
		
		set tree $Priv(win,tree)		
		set ret [list]
		foreach item [$tree item children 0] {
			if {[$tree item state get $item "CHECK"]} {
				lappend ret $item
			}
		}
		return $ret
	}
	
	method item_clear {} {
		my variable Priv
		set tree $Priv(win,tree)
		
		foreach item [$tree item children 0] {$tree item delete $item	}
	}
	
	method item_click {x y} {
		my variable Priv
		
		set tree $Priv(win,tree)
				
		set itemInfo [$tree identify $x $y]
		if {[llength $itemInfo] != 6} {return}
		array set opts $itemInfo
		if {$opts(elem) == "check"} {
			if { [$tree item state get $opts(item) "CHECK"] } {
				set state "!CHECK"
			} else {
				set state "CHECK"
			}
			my row_check_click $opts(item) $state
		}
		
		if {$opts(elem) == "delete"} {
			my row_delete_click $opts(item)
		}
		
		if {$opts(elem) == "edit"} {
			my row_edit_click $opts(item)
		}
	}		
	
	method item_delete {item} {
		my variable Priv
		set tree $Priv(win,tree)
		
		$tree item delete $item		
	}
	
	method item_motion {x y} {
		my variable Priv
		
		set tree $Priv(win,tree)
		
		
		foreach item [$tree item children 0] {
			$tree item element configure $item _OPERATION_ "delete" -fill $Priv(opts,linkColor)
			$tree item element configure $item _OPERATION_ "edit" -fill $Priv(opts,linkColor)					
		}
						
		set itemInfo [$tree identify $x $y]

		if {[llength $itemInfo] != 6} {
			$tree configure -cursor ""
			return
		}
		array set opts $itemInfo
		if {$opts(elem) == "delete" || $opts(elem) == "edit"} {
			$tree item element configure $opts(item) $opts(column) $opts(elem) -fill $Priv(opts,linkMotionColor)
			$tree configure -cursor $Priv(opts,linkCursor)
			return
		}
		$tree configure -cursor ""
	}
	
	method refresh_start {{filter ""}} {
		my variable Priv
		
		if {$filter == "" } {set filter $Priv(opts,filter)}
		
		set Priv(opts,total) [my count $filter]
		if {$Priv(opts,orderBy) != ""} {
			append filter " ORDER BY $Priv(opts,orderBy) $Priv(opts,order)"
		}			
		set offset [expr $Priv(opts,itemsPerPage) * ($Priv(opts,currPage) -1)]
		append filter " LIMIT $Priv(opts,itemsPerPage) OFFSET $offset"
	
		my refresh $filter 
		
		my sbar_update
	}
	
	method sbar_ctrl_init {wpath} {
		my variable Priv
		
		set fmeCtrl [ttk::frame $wpath]
		
		pack [ttk::button $fmeCtrl.btnNext \
			-image $Priv(img,next) \
			-style Toolbutton \
			-command [list [self object] sbar_next] \
		] -side  right -padx 3
		
		pack [ttk::combobox $fmeCtrl.cmbGoto \
			-textvariable [self namespace]::Priv(opts,currPage) \
			-width 3 \
			-state readonly \
		] -side  right
		
		pack [ttk::button $fmeCtrl.btnPrev \
			-image $Priv(img,prev) \
			-style Toolbutton \
			-command [list [self object] sbar_prev] \
		] -side  right -padx 3			
		
		
		pack [ttk::label $fmeCtrl.lblInfo \
			-text [::msgcat::mc "1-30 (總共: %s)" $Priv(opts,total)]  \
		] -side right -padx 4
		
		pack [ttk::combobox $fmeCtrl.cmbRows \
			-textvariable [self namespace]::Priv(opts,itemsPerPage) \
			-values [list 10 25 50 100 200 300]\
			-width 5 \
			-state readonly \
		] -side  right -padx 5
		
		pack [ttk::label $fmeCtrl.lblRows -text [::msgcat::mc "顯示列數:"]] -side right -padx 2
		
		bind $fmeCtrl.cmbGoto <<ComboboxSelected>> [list [self object] sbar_find]
		bind $fmeCtrl.cmbRows <<ComboboxSelected>> [list [self object] sbar_rows]
		
		set Priv(win,lblInfo) $fmeCtrl.lblInfo
		set Priv(win,cmbRows) $fmeCtrl.cmbRows
		set Priv(win,cmbGoto) $fmeCtrl.cmbGoto
		
		if {$Priv(opts,showctrl) == 1} {
			pack $fmeCtrl -expand 1 -fill both -side right
		}			
		set Priv(win,ctrl) $fmeCtrl
		return $fmeCtrl
	}
	
	method sbar_filter_init {wpath} {
		my variable Priv
		
		set Priv(var,cmbFields) ""
		set Priv(var,txtKeyword) ""
		
		set fmeFilter [ttk::frame $wpath]
		pack [ttk::label $fmeFilter.lblFilter -text [::msgcat::mc "快速搜尋:"]] -side left -padx 2
		pack [ttk::combobox $fmeFilter.cmbFields \
			-textvariable [self namespace]::Priv(var,cmbFields) \
			-width 14 \
			-state readonly \
		] -side  left -padx 3

		pack [ttk::entry $fmeFilter.txtKeyword \
			-textvariable [self namespace]::Priv(var,txtKeyword) \
		] -side  left -padx 3
		pack [ttk::button $fmeFilter.btnFilter \
			-image $Priv(img,filter) \
			-style Toolbutton \
			-command [list [self object] sbar_find] \
		] -side  left -padx 3
		
		bind $fmeFilter.txtKeyword <Return> [list $fmeFilter.btnFilter invoke]
		
		if {$Priv(opts,showfilter) == 1} {
			pack $fmeFilter -expand 1 -fill both -side left
		}
		
		set Priv(win,cmbFields) $fmeFilter.cmbFields
		set Priv(win,filter) $fmeFilter	
		
		return $fmeFilter	
	}	
	
	method sbar_find {} {
		my variable Priv
		
		set tree $Priv(win,tree)
		set keyword [string trim [string map [list "\'" ""] $Priv(var,txtKeyword)]]
		set filter ""
		if {$keyword != ""} {
			set name $Priv(var,cmbFields)
			set col ""
			foreach {c} [$tree column list] {
				set txt [$tree column cget $c -text]
				if {$txt == $name} {
					set col [$tree column tag names $c]
					break
				}
			}
			if {$col == ""} {return}
			append filter " $col LIKE '%" $keyword "%' "
		}
		
		my refresh_start		$filter
	}
	
	method sbar_init {wpath} {
		my variable Priv
		
		set sbar [ttk::frame $wpath]
		set Priv(win,sbar) $sbar
		
		my  sbar_filter_init $sbar.fmeFilter
		my sbar_ctrl_init $sbar.fmeCtrl
		
		if {$Priv(opts,showsbar)} {grid $sbar - -sticky "news"}
		return $sbar
	}
	
	method sbar_next {} {
		my variable Priv
		
		if {$Priv(opts,currPage) + 1 > $Priv(opts,pages)} {return}
		incr Priv(opts,currPage)
		my sbar_find		
	}
	
	method sbar_rows {} {
		my variable Priv
		
		set Priv(opts,currPage) 1
		my sbar_find	
	}	
	
	method sbar_prev {} {
		my variable Priv
		
		if {$Priv(opts,currPage) - 1 == 0} {return}
		incr Priv(opts,currPage) -1
		my sbar_find	
	}	
	
	method sbar_update {} {
		my variable Priv
		
		set tree $Priv(win,tree)
		
		$tree column configure _CHECK_ -justify left
		
		set start [expr ($Priv(opts,currPage) -1) * $Priv(opts,itemsPerPage) + 1]
		set cut [expr $start + [llength [$tree item children 0]] - 1]
		$Priv(win,lblInfo) configure -text [::msgcat::mc "%s-%s (總共:%s)" $start $cut $Priv(opts,total)]
		
		set Priv(opts,pages) [expr $Priv(opts,total) / $Priv(opts,itemsPerPage)]
		if {$Priv(opts,total) % $Priv(opts,itemsPerPage)} {incr Priv(opts,pages)}
		set values [list]
		for {set i 1} {$i <= $Priv(opts,pages)} {incr i} {
			lappend values $i
		}
		
		$Priv(win,cmbGoto) configure -values $values	
		
		set value [$Priv(win,cmbFields) get]
		set values [list]
		foreach col [$tree column list -visible] {
			set tag [$tree column cget $col -tags]
			if {$tag == "_CHECK_" || $tag == "_OPERATION_"} {continue}
			lappend values [$tree column cget $col -text]
		}
		$Priv(win,cmbFields) configure -value $values
		if {[lsearch -exact $values $value] == -1 || $value == ""} {
			set Priv(var,cmbFields) [lindex $values 0]		
		}
		
	}
	method Ui_Init {} {
		my variable Priv

		set fmeMain [ttk::frame $Priv(win,frame) -borderwidth 0 -relief groove ]
		set tree [treectrl $fmeMain.tree \
			-height 300 \
			-width 300 \
			-showroot no \
			-showline no \
			-selectmod signle \
			-showrootbutton no \
			-showbuttons no \
			-showheader yes \
			-scrollmargin 16 \
			-highlightthickness 0 \
			-relief groove \
			-bg white \
			-bd 0 \
			-font TableviewItemFont\
			-usetheme 1 \
			-xscrolldelay "500 50" \
			-yscrolldelay "500 50"]
			
		set vs [ttk::scrollbar $fmeMain.vs -command [list $tree yview] -orient vertical]
		set hs [ttk::scrollbar $fmeMain.hs -command [list $tree xview] -orient horizontal]
		$tree configure -xscrollcommand [list $hs set] -yscrollcommand [list $vs set]
		
		::autoscroll::autoscroll $vs
		::autoscroll::autoscroll $hs	
		
		grid $tree $vs -sticky "news"
		grid $hs - -sticky "news"
		grid rowconfigure $fmeMain 0 -weight 1
		grid columnconfigure $fmeMain 0 -weight 1			

		set Priv(win,tree) $tree

		$tree state define CHECK
		$tree notify install <Header-invoke>

		$tree element create rect rect -open nw -fill [list "#d6d9dc" {selected}] -outline "#e0e0e0" -outlinewidth 1
		$tree element create check image \
			-image [list $Priv(img,check) CHECK $Priv(img,uncheck) {} ]
		$tree element create image image
		$tree element create image1 image
		$tree element create image2 image
		$tree element create image3 image
		$tree element create text text

		$tree element create edit text -fill $Priv(opts,linkColor) -text [::msgcat::mc "編輯"]
		$tree element create sep text  -text "|"
		$tree element create delete text -fill $Priv(opts,linkColor) -text [::msgcat::mc "刪除"]
	
		set pad $Priv(opts,padding)
		$tree style create text
		$tree style elements text [list rect text]
		$tree style layout text text -iexpand nes -padx $pad -pady 3
		$tree style layout text rect -union {text} -iexpand news 
		
		$tree style create itext
		$tree style elements itext [list rect image text]
		$tree style layout itext image  -iexpand ns -padx "$pad 2" -pady 3
		$tree style layout itext text -iexpand nes  -padx "0 $pad"  -pady 3
		$tree style layout itext rect -union {image text} -iexpand news 
		
		$tree style create check
		$tree style elements check [list rect check text]
		$tree style layout check check -iexpand news -ipadx $pad -ipady 3
		$tree style layout check text -draw 0
		$tree style layout check rect -union {check} -iexpand news
		
		$tree style create ioperation
		$tree style elements ioperation [list rect image1 image2 image3]
		$tree style layout ioperation image1 -pady 3 -padx "$pad 0" -iexpand nsw
		$tree style layout ioperation image2 -pady 3 -padx $pad -iexpand ns
		$tree style layout ioperation image3 -pady 3 -padx $pad -iexpand nse
		$tree style layout ioperation rect -union {image1 image2 image3} -iexpand news		
		
		$tree style create operation
		$tree style elements operation [list rect edit sep delete]
		$tree style layout operation edit -pady 3 -padx "$pad 0" -iexpand news  -sticky news
		$tree style layout operation sep -pady 3 -padx $pad -iexpand ns
		$tree style layout operation delete -pady 3 -padx "0 $pad"  -iexpand news -sticky news
		$tree style layout operation rect -union {edit sep delete} -iexpand news				
		
		if {$Priv(opts,showedit) == 0} {
			$tree style layout operation edit -width 0 -padx 0 -pady 0 -expand "" -iexpand ""
		}
		if {$Priv(opts,showdelete) == 0} {
			$tree style layout operation delete -width 0 -padx 0 -pady 0 -expand "" -iexpand ""
		}
		if {$Priv(opts,showdelete) == 0 || $Priv(opts,showedit) == 0} {
			$tree style layout operation sep -width 0 -padx 0 -pady 0 -expand "" -iexpand ""
		}
		$tree column create -tags _CHECK_ \
			-arrow none \
			-itemstyle check \
			-justify left \
			-resize 0 \
			-textpady 3 \
			-borderwidth  $Priv(opts,columnbd) \
			-textcolor $Priv(opts,columncolor) \
			-visible $Priv(opts,showcheck)
			
		$tree column create -tags _OPERATION_ \
			-arrow none \
			-itemstyle operation \
			-resize 0 \
			-textpady 3 \
			-font TableviewHeaderFont \
			-borderwidth $Priv(opts,columnbd) \
			-textcolor black \
			-text [::msgcat::mc "動作"] \
			-visible $Priv(opts,showops)
			
		bind $tree <<ButtonL-Click>> [list [self object] item_click %x %y]
		bind $tree <Motion> [list [self object] item_motion %x %y]		
		$tree notify bind $tree <Header-invoke> [list [self object] column_click %C]


		my sbar_init $fmeMain.sbar
		
		#my filter_start
		return $fmeMain
	}
}

#set tv [::ddb::tableview new .tv]
#pack .tv -expand 1 -fill both
#
#
#$tv column_add tel -text "Tel" -itemstyle text
#
#$tv item_add tel 0920
#
#$tv refresh_start

