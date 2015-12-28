ttk::style configure Title.TLabel -borderwidth 0 -background white

ttk::style layout Title.Radiobutton {

		Checkbutton.padding -sticky nswe -children {
			Checkbutton.label -sticky nswe
		}

}
ttk::style map Title.Radiobutton -relief {
	{selected !disabled} sunken
	{!selected !disabled} flat
} 

ttk::style map Home.Title.Radiobutton -image [list \
		{selected !disabled} [image create photo -file home_check.png] \
		{!selected !disabled} [image create photo -file home_uncheck.png] \
]

set fme [frame .fme -background white]

set ::v1 1
. configure -background white
ttk::label $fme.lblL -image [image create photo -file left.png] -style Title.TLabel
ttk::label $fme.lblS1 -image [image create photo -file separator.png] -style Title.TLabel
ttk::radiobutton $fme.lblC -style Home.Title.Radiobutton -variable ::v1 -value 1
ttk::radiobutton $fme.lblC2 -style Home.Title.Radiobutton  -variable ::v1 -value 2
ttk::radiobutton $fme.lblC3 -style Home.Title.Radiobutton  -variable ::v1 -value 3
ttk::label $fme.lblS2 -image [image create photo -file separator.png] -style Title.TLabel
ttk::label $fme.lblR -image [image create photo -file right.png] -style Title.TLabel


pack $fme -fill x 

pack $fme.lblL $fme.lblS1 $fme.lblC $fme.lblC2 $fme.lblC3 $fme.lblS2 $fme.lblR -side left

$fme.lblC configure -width 50
