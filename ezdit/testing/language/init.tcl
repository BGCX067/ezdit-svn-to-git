package require ttdialog
package require ttparser

namespace eval ::cc {
	variable Priv

	array set Priv [list \
		appPath "" \
		pluginPath "" \
		extensions [list .c .cc .cpp .cxx .h] \
		re,digit {[-+]?([0-9]+[xX]?\.?[0-9a-fA-F]*|\.[0-9]+)([eE][-+]?[0-9]+)?} \
	]

	variable SYNDB
	array set SYNDB [list]


	proc init {appPath pluginPath} {
		variable Priv
		variable SYNDB
		
		set Priv(appPath) $appPath
		set Priv(pluginPath) $pluginPath
	
		source [file join $Priv(pluginPath) "syndb"]
		::cc::syn_init
		
		 set Priv(mdu) [::ezplug::language_module_install \
			-extensions [list .c .h .cc .cpp .C .H .CC .CPP] \
			-comment "//" \
			-highlightInitCmd "::cc::editor_init_cb" \
			-highlightCmd "::cc::editor_highlight_cb" \
			-outlineCmd "::cc::cbrowser_outline_cb" \
			-keyCmd "::cc::editor_key_cb" \
			-hintCmd ""	 \
			-bracketMatchCmd "default"]
	}

	proc cleanup {} {
		variable Priv
		variable SYNDB
		
		 ::ezplug::language_module_uninstall $Priv(mdu)
			
		array unset SYNDB
		
	}
	
	proc cbrowser_outline_cb {cbrowser editor wtext} {
		variable Priv
	
		set ibox $::dApp::Priv(ibox)
	
		set data [$wtext get 1.0 end]
			
		return
	}
	
	proc editor_highlight_cb {editor wtext sIdx eIdx} {
		variable Priv
		variable SYNDB
		
		set idx1 $sIdx
		set idx2 $eIdx
		if {$sIdx == "insert linestart" && $eIdx == "insert"} {
			set idx2 "insert lineend"
		}
		set data [$wtext get $idx1 $idx2]

		foreach {tag spec} $SYNDB(_COLORS_) {$wtext tag remove $tag $idx1 $idx2}
		
		::cc::parse $wtext data $idx1
		
		
		return
	}
	
	proc editor_init_cb {editor wtext fpath} {
		variable Priv
		variable SYNDB
		
		foreach {tag spec} $SYNDB(_COLORS_) {
			lassign $spec color font
			$wtext tag configure $tag -foreground $color 
			$wtext tag raise $tag
			if {$font != ""} {$wtext tag configure $tag -font $font }
		}
	}
	
	proc editor_key_cb {editor wtext type key} {
		variable Priv
		
		if {$key == "braceright"} {
			set data [$wtext get "insert linestart" "insert lineend"]
			if {[string trim $data] == "\}"} {
				set tabwidth [$editor cget -tabwidth]
				set sp [string repeat " " $tabwidth]
				regsub {\t} $data $sp data
				regsub $sp $data "" data
				$wtext replace "insert linestart" "insert lineend" $data		
			}
			return
		}
		
		if {$key == "Return" || $key == "KP_Enter"} {
			set currIdx [$wtext index insert]
			lassign [split $currIdx "."] line char
			incr line -1
			set data [$wtext get $line.0 "$line.0 lineend"]
			set pad ""
			regexp {^\s+} $data pad
			if {[string index [string trimright $data] end] == "\{"} { set pad "\t$pad"}
			$wtext insert insert $pad
			set currIdx $line.0
			return
		}
		
		
		
	}
	
	proc parse {wtext varName sIdx {len 0}} {
		variable SYNDB
		variable Priv
		
		upvar $varName data

		set chars $SYNDB(_CHARS_)
		lassign [::cc::tok data 0] type idx1 idx2 endch
		
		if {$len > 0 && $idx2 > $len} {return [list "EOF" $idx1 $len]}

		while {$type != "EOF"} {
			if {$type != "EOS"} {
				set ch [string index $data $idx1]
				set ch2 [string index $data [expr $idx1 + 1]]
				set tok [string range $data $idx1 $idx2]
				incr idx2
				if {$ch == "\"" || $ch == "\'"} {
					set idx2 [::cc::match_string data $idx1]
					incr idx2
					$wtext tag add "STRING" "$sIdx + $idx1 chars" "$sIdx + $idx2 chars"
				} elseif {$ch == "/" && $ch2 == "/"} {
					set len [string length [$wtext get "$sIdx + $idx1 chars" "$sIdx + $idx2 chars lineend"]]
					set idx2 [expr $idx1+$len]
					$wtext tag add "COMMENT" "$sIdx + $idx1 chars" "$sIdx + $idx2 chars"
				} elseif {[string first $ch ".0123456789"] >= 0} {
					set idx2 [::cc::match_digit data $idx1]
					incr idx2
					$wtext tag add "DIGIT" "$sIdx + $idx1 chars" "$sIdx + $idx2 chars"
				} elseif {[info exists SYNDB($tok)]} {
					$wtext tag add $SYNDB($tok) "$sIdx + $idx1 chars" "$sIdx + $idx2 chars"
				}
			}
			lassign [::cc::tok data [incr idx2]] type idx1 idx2 endch
			if {$len > 0 && $idx2 > $len} {return [list "EOF" $idx1 $len]}
		}
	}
	
	proc match_digit {varName sIdx} {
		upvar $varName data
		set idx1 $sIdx
		set ch [string index $data $idx1]
		
      set ch2 [string index $data [incr idx1]]
      while {$ch2 != ""} {
         if {[string first $ch2 ".0x123456789"] == -1} {return [incr idx1 -1]}
         set ch2 [string index $data [incr idx1]]
      }
      return [incr idx1 -1]
	}	

	proc match_string {varName sIdx} {
		upvar $varName data
		set idx1 $sIdx
		set ch [string index $data $idx1]
		
      set ch2 [string index $data [incr idx1]]
      while {$ch2 != ""} {
         if {$ch2 == $ch} {break}
         if {$ch2 == "\\"} {incr idx1}       
         set ch2 [string index $data [incr idx1]]
      }
      if {$ch2 == ""} {incr idx1 -1}
      return $idx1
	}

	proc tok {varName sIdx} {
		variable SYNDB
		
		upvar $varName data
		set idx1 $sIdx
		   
		# skip space
		set idx1 $sIdx
		set ch [string index $data $idx1]
		
		while {$ch == " "  || $ch == "\t"} {
			 incr idx1
			 set ch [string index $data $idx1]
		}
		set idx2 $idx1
		
		if {$ch == ""} {return [list "EOF" $idx1 $idx2 ""]}
		
		if {$ch == "\n" || $ch == "\r"} {
			set ch2 [string index $data [expr $idx2 + 1 ]]
			if {$ch2 == "\n" || $ch2 == "\r"} {incr idx2}
			return [list "EOS" $idx1 $idx2 ""]
		}
		
		set chars $SYNDB(_CHARS_)
		 while {1==1} {
			if {[string first $ch $chars] < 0} {return [list "TOK" $idx1 [incr idx2 -1] $ch]}
			 set ch [string index $data [incr idx2]]
		 }
		 return [list "EOF" $idx1 $idx2]
	}
}
