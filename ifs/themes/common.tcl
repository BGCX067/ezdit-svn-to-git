ttk::style configure White.TFrame -background white
ttk::style configure Field.TLabel -background white -foreground "#004080"
ttk::style configure Red.Field.TLabel -background white -foreground "#804040"

ttk::style configure Position.TLabel \
	-foreground "#800000" \
	-font [font create -family "新細明體" -size 9 -weight bold]

ttk::style layout Field.TEntry {
	Entry.border -sticky nswe -border 1 -children {
		 Entry.padding -sticky nswe -children {
			 Entry.plain.background -sticky nswe -children {
			 	Entry.textarea -sticky nswe
		 	}
	 	}
	}
}
ttk::style configure Field.TEntry -background white -padding 4 -relief solid
ttk::style map Field.TEntry -background {
	{focus} yellow
	{invalid} "#ffb3b3"
}


ttk::style layout  Field.TCombobox {
	Combobox.border -sticky nswe -border 1 -children {
		Combobox.downarrow -side right -sticky ns Combobox.padding -expand 1 -sticky nswe -children {
			Combobox.focus -expand 1 -sticky nswe -children {
				Combobox.textarea -sticky nswe
			}
		}
	}
}

ttk::style configure Field.TCombobox -background white -padding 4 -relief solid
ttk::style map Field.TCombobox -background {
	{focus} yellow
	{invalid} red
}


