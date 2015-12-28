package require Tk
text .txt -wrap none -cursor none
button .btn -text "show" -command {.txt configure -cursor ""}
pack .txt .btn 


