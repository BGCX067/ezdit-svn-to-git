package require base64

button .btn -text "Choose" -command {
	set ans [tk_getOpenFile]
	if {[file exists $ans]} {
		set fd [open $ans r]
		fconfigure $fd -encoding "binary" -translation binary
		set data [base64::encode [read $fd]]		
		close $fd
		
		.txt insert end $data
	}
}

text .txt

pack .txt -expand 1 -fill both
pack .btn -fill x 
