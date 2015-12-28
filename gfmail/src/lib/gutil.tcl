package provide gutil 1.0

#set ::auto_path [linsert ::auto_path 0 ./ ../lib_darwin]
#source smtp.tcl

package require mime
package require fileutil::magic::mimetype	
package require base64
package require imap
package require smtp

namespace eval ::gutil {
	variable Priv
	array set Priv [list msg "" msgTid "" stop 0]
}

proc ::gutil::mkdir {user passwd mbox args} {
	variable Priv
	
	array set opts [list \
		-server "imap.gmail.com" \
		-port "993" \
		-user $user \
		-passwd $passwd \
	]
	array set opts $args

	set imap [::imap::connect $opts(-server) $opts(-port) $opts(-user) $opts(-passwd) -tls 1]
	if {$imap == ""} {return 0}
	set ret 0
	if {![$imap select $mbox]} {
		set ret [$imap create $mbox]
	} else {
		set ret 1
	}
	$imap disconnect
	return $ret
}

proc ::gutil::delete {user passwd subjectList args} {
	
	array set opts [list \
		-server "imap.gmail.com" \
		-port "993" \
		-user $user \
		-passwd $passwd \
		-mbox "GDisk" \
		-command "::gutil::cbtest" \
	]
	array set opts $args
	
	eval [linsert $opts(-command) end 4 1]
	set imap [::imap::connect $opts(-server) $opts(-port) $opts(-user) $opts(-passwd) -tls 1]
	if {$imap == ""} {
		eval [linsert $opts(-command) end 4 4]
		return 0
	}
	eval [linsert $opts(-command) end 4 2]
	if {![$imap select $opts(-mbox)]} {$imap disconnect ; return 0	}
	eval [linsert $opts(-command) end 4 3]
	foreach subject $subjectList {
		if {![$imap search [format {Subject "%s"} $subject]]} {$imap disconnect ; return 0	}
		set id [lindex [$imap response data] end]
		if {$id == ""} {continue}
		if {![$imap copy $id {[Gmail]/&V4NXPmh2-}]} {$imap disconnect ; return 0	}
	}
	eval [linsert $opts(-command) end 4 4]
	$imap disconnect

	return 1
}

proc ::gutil::download {user passwd subject fpath args} {
	
	array set opts [list \
		-server "imap.gmail.com" \
		-port "993" \
		-user $user \
		-passwd $passwd \
		-file $fpath \
		-command "::gutil::cbtest" \
		-mbox "GDisk" \
	]
	array set opts $args
	
	set imap [::imap::connect $opts(-server) $opts(-port) $opts(-user) $opts(-passwd) -tls 1]
	if {$imap == ""} {return 0}

	if {![$imap select $opts(-mbox)]} {$imap disconnect ; return 0}
	
	if {![$imap search [format {Subject "%s"} $subject]]} {$imap disconnect ; return 0	}
	set id [lindex [$imap response data]	end]
	if {$id == ""} {$imap disconnect ; return 0} 

	if {![$imap fetch "$id (UID RFC822.SIZE)"]} {$imap disconnect ; return 0	}
	set data [$imap response data]
	set idx1 [expr [string first "(" $data]+1]
	set idx2 [expr [string first ")" $data]-1]
	lassign [string range $data $idx1 $idx2] key uid key2 size


	if {![$imap fetch "$id BODY\[TEXT\]" [linsert $opts(-command) end $size] 4096]} {$imap disconnect ; return 0	}
	set data [$imap response data]
	set idx1 [string first base64 $data]
	if {$idx1 == -1} {set idx1 [string first BASE64 $data]}
	set idx1 [string first "\r\n\r\n" $data $idx1]
	set idx2 [string first "-------" $data [expr $idx1 + 4]]
	set data [string range $data $idx1 [expr $idx2 - 1]]

	set fd [open $opts(-file) w]
	chan configure $fd -translation binary
	chan puts -nonewline $fd [::base64::decode $data]
	chan close $fd


	eval [linsert $opts(-command) end $size $size]

	$imap disconnect
	return 1
	
}

proc ::gutil::upload {user passwd subject body args} {
	array set opts [list \
		-smtpServer "smtp.gmail.com" \
		-smtpPort "25" \
		-imapServer "imap.gmail.com" \
		-imapPort "993" \
		-user $user \
		-passwd $passwd \
		-mbox "GDisk" \
		-file "" \
		-command "::gutil::cbtest" \
		-start 0 \
		-len 0 \
	]

	array set opts $args
	
	set parts [::mime::initialize -canonical "text/plain" -string $body]

	set fname [file tail $opts(-file)].part.$opts(-start)

	if {$opts(-file) != ""} {
		set type [lindex [fileutil::magic::mimetype $opts(-file)] end]
		if {$type == ""} {set type "text/plain"}
		if {$opts(-len) == 0} {
			set att [::mime::initialize -encoding base64 \
						-canonical [format {%s; name="%s";} $type $fname] \
						-file $opts(-file) \
						-header {Content-Disposition attachment} ]
		} else {
			set fd [open $opts(-file) r]
			chan configure $fd -encoding binary -translation binary
			chan seek $fd $opts(-start) start
			set att [::mime::initialize -encoding base64 \
						-canonical [format {%s; name="%s";} $type $fname] \
						-string [read $fd $opts(-len)] \
						-header {Content-Disposition attachment} ]			
			close $fd
		}
		lappend parts $att
		set msg [::mime::initialize -canonical "multipart/mixed" -parts $parts]
	} else {
		set msg $parts
	}
	
	set ret 1
	set smtp [::smtp::connect $opts(-smtpServer) $opts(-smtpPort) $user $passwd -tls 1]
	set ret [$smtp send $subject "$user@gmail.com" "$user@gmail.com" $msg $opts(-command)]
	$smtp  disconnect
	::mime::finalize $msg -subordinates all
	if {$ret == 0} {return 0}
	
	
	set imap [::imap::connect $opts(-imapServer) $opts(-imapPort) $user $passwd -tls 1]
	if {$imap == ""} {return 0}
	
	if {![$imap select "INBOX"]} {$imap disconnect ; return 0}

	if {![$imap search [format {Subject "%s"} $subject]]} {{$imap disconnect ; return 0	}}
	set id [lindex [$imap response data] end]
	if {$id == ""} {$imap disconnect ; return 0} 

	set ret 1
	if { ![$imap store "$id +FLAGS (\\Seen \\Deleted)"] || ![$imap copy $id $opts(-mbox)]} {set ret 0}
	

	$imap disconnect
	
	return $ret
}

proc ::gutil::msg_put {msg {tout 2500}} {
	variable Priv
	if {$Priv(msgTid) != ""} {
		catch {after cancel $Priv(msgTid)}
	}
	set ::gutil::Priv(msg) $msg

	if {$tout > 0} {
		set Priv(msgTid) [after $tout {
			set ::gutil::Priv(msg) ""
			set ::gutil::Priv(msg) ""
			set Priv(msgTid) ""
		}]
	}
	
	return
}

proc ::gutil::cbtest {max curr} {}

#set user "dai.gdisk.1"
#set passwd "1qaz1qaz"
#puts mkdir=[::gutil::mkdir $user $passwd ee]
#puts [::gutil::upload $user $passwd "Subject 007" "01.zip" -file "01.zip" -command ::cbtest]
#puts [::gutil::download $user $passwd "Subject 007" "02.zip" -command ::cbtest]
#puts [::gutil::delete $user $passwd [list "Subject 007"]]

#exit
