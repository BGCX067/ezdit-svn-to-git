package require tdom
package provide ttrc 1.0

namespace eval ::ttrc {
	variable sn 0
	variable Priv
	array set Priv [list]
}

proc ::ttrc::dispatch {tok args} {
	variable Priv
	set cmd [list ::ttrc::cmd_[lindex $args 0] $tok]
	foreach arg [lrange $args 1 end] {lappend cmd $arg}
	return [eval $cmd]	
}

proc ::ttrc::openrc {fpath} {
	variable Priv
	variable sn
	
	set data {<?xml version="1.0" encoding="UTF-8" ?><ttrc></ttrc>}
	if {[file exists $fpath]} {
		set fd [open $fpath r]
		chan configure $fd -encoding utf-8
		set data [read $fd]
		chan close $fd
	}
	incr sn
	set tok ::ttrc::cmd$sn
	interp alias {} $tok {} ::ttrc::dispatch $tok	
	
	set Priv($tok,doc) [dom parse $data]
	set Priv($tok,file) $fpath
	
	return $tok
}

proc ::ttrc::cmd_close {tok} {
	variable Priv
	
	set doc $Priv($tok,doc)
	set fpath $Priv($tok,file)
	set root [$doc documentElement ]
	
	set fd [open $fpath w]
	fconfigure $fd -encoding "utf-8"
	puts $fd [$doc asXML]
	close $fd
	
	$doc delete
	array unset Priv $tok,*
	interp alias {} $tok {} {}
}

proc ::ttrc::cmd_save {tok} {
	variable Priv
	
	set doc $Priv($tok,doc)
	set fpath $Priv($tok,file)
	set root [$doc documentElement ]
	
	set fd [open $fpath w]
	fconfigure $fd -encoding "utf-8"
	puts $fd [$doc asXML]
	close $fd
}

proc ::ttrc::cmd_session_add {tok name} {
	variable Priv
	
	set doc $Priv($tok,doc)
	set fpath $Priv($tok,file)
	set root [$doc documentElement ]	
	foreach node [$root selectNodes "/ttrc/$name" ] {return $node}	
	set nodeSess [$doc createElement $name]
	$root appendChild $nodeSess
	return $nodeSess
}

proc ::ttrc::cmd_session_del {tok session} {
	variable Priv	
	set doc $Priv($tok,doc)
	set fpath $Priv($tok,file)
	set root [$doc documentElement ]	
	set parent [$session parentNode]
	$parent removeChild $session

	return
}

proc ::ttrc::cmd_session_select {tok name} {
	variable Priv	
	set doc $Priv($tok,doc)
	set fpath $Priv($tok,file)
	set root [$doc documentElement ]	
	foreach node [$root selectNodes "/ttrc/$name" ] {return $node}	

	return ""
}

proc ::ttrc::cmd_session_items {tok session} {
	variable Priv	
	
	set doc $Priv($tok,doc)
	set fpath $Priv($tok,file)
	set root [$doc documentElement ]
	
	return [$session childNodes]
}

proc ::ttrc::cmd_item_add {tok session name } {
	variable Priv
	
	set doc $Priv($tok,doc)
	set fpath $Priv($tok,file)
	set root [$doc documentElement ]	
	set nodeNew [$doc createElement $name]
	$session appendChild $nodeNew
	
	return	$nodeNew
}

proc ::ttrc::cmd_item_del {tok item} {
	variable Priv
	
	set doc $Priv($tok,doc)
	set fpath $Priv($tok,file)
	set root [$doc documentElement ]	
	
	set parent [$item parentNode]
	$parent removeChild $item
	
	return	$item	
}

proc ::ttrc::cmd_item_name {tok item} {
	variable Priv
	
	set doc $Priv($tok,doc)
	set fpath $Priv($tok,file)
	set root [$doc documentElement ]	
	
	return	[$item nodeName]	
}

proc ::ttrc::cmd_item_parent {tok item} {
	variable Priv	
	set doc $Priv($tok,doc)
	set fpath $Priv($tok,file)
	set root [$doc documentElement ]	
	return [$item parentNode]
}

proc ::ttrc::cmd_item_query {tok item xpath} {
	variable Priv	
	set doc $Priv($tok,doc)
	set fpath $Priv($tok,file)
	set root [$doc documentElement ]	
	return [$item selectNodes $xpath ]
}

proc ::ttrc::cmd_item_select {tok session name} {
	variable Priv	
	set doc $Priv($tok,doc)
	set fpath $Priv($tok,file)
	set root [$doc documentElement ]	
	foreach node [$session selectNodes "$name" ] {return $node}	

	return ""
}

proc ::ttrc::cmd_attr_set {tok item args} {
	variable Priv
	
 	set doc $Priv($tok,doc)
	set fpath $Priv($tok,file)
	set root [$doc documentElement ]	
	
	foreach {key val} $args {$item setAttribute $key $val}

	
	return	$item	
 }
 
 proc ::ttrc::cmd_attr_del {tok item attr} {
	variable Priv
	
 	set doc $Priv($tok,doc)
	set fpath $Priv($tok,file)
	set root [$doc documentElement ]	
	
	$item removeAttribute $attr

	
	return	$item	
 }
 
 proc ::ttrc::cmd_attr_get {tok item key} {
	variable Priv
	
 	set doc $Priv($tok,doc)
	set fpath $Priv($tok,file)
	set root [$doc documentElement ]	

	return	[$item getAttribute $key]	
 }
 
proc ::ttrc::cmd_attr_list {tok item} {
	variable Priv
	
 	set doc $Priv($tok,doc)
	set fpath $Priv($tok,file)
	set root [$doc documentElement ]	

	return	[$item attributes]	
 }

#set tok [::ttrc::openrc "~/tmp/a.xml"]
#set sess [$tok session_add "dai"]
#$tok item_add $sess "years"
#set item [$tok item_add $sess "tal"]
#$tok attr_set $item "src" "c:/" "id" 01
#puts items=[$tok session_items $sess]
#
#puts attrs=[$tok attr_list $item]
#
#$tok attr_del $item id
#
#
#$tok close
