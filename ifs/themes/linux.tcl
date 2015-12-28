ttk::style configure Heading.TNotebook -tabposition nw -tabmargins {50 43 50 0}
ttk::style configure Tab -padding {6 2 6 2}
ttk::style configure Heading.Toolbutton -padding 0 -boder 0
	
ttk::style map Start.Heading.Toolbutton -image [list \
	{!hover !disabled !pressed} [$::dApp::Obj(ibox) get start1] \
	{hover !disabled !pressed} [$::dApp::Obj(ibox) get start2] \
	{pressed !disabled} [$::dApp::Obj(ibox) get start1] \
] -background [list \
	{hover !disabled} [. cget -background] \
	{!hover !disabled} [. cget -background] \
] -border [list \
	{hover !disabled} 0 \
	{!hover !disabled} 0 \
] -relief [list \
	{hover !disabled} flat \
	{!hover !disabled} flat \
]

ttk::style configure Close.Heading.Toolbutton -relief flat

ttk::style map Close.Heading.Toolbutton -image [list \
	{disabled} [$::dApp::Obj(ibox) get close1] \
	{!hover !disabled !pressed} [$::dApp::Obj(ibox) get close1] \
	{hover !disabled !pressed} [$::dApp::Obj(ibox) get close1] \
	{pressed !disabled} [$::dApp::Obj(ibox) get close1] \
] -background [list \
	{hover !disabled} [. cget -background] \
	{!hover !disabled} [. cget -background] \
] -border [list \
	{hover !disabled} 1 \
	{!hover !disabled} 0 \
] -relief [list \
	{hover !pressed !disabled} raised \
	{hover pressed !disabled} sunken \
	{disabled} flat \
]


#######################Flat Button#####################

ttk::style layout Flat.Toolbutton {
	Button.border -sticky nswe -border 1 -children {
		Button.padding -sticky nswe -children {
			Button.label -sticky nswe
		}
	}
}

ttk::style configure  Flat.Toolbutton \
	-width 0 \
	-border 0 \
	-anchor center  \
	-padding {15 3 15 1} \
	-relief flat \
	-foreground "#505050" \
	-takefocus 0

ttk::style map Flat.Toolbutton -relief {
	{pressed !disabled} sunken
} -background {
	{hover active} "#aeacc1"
} -foreground {
	{hover active} "white"
} 

