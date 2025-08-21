/datum/language/abyssal
	name = "Abyssal"
	desc = "The language of the inhabitants of the sea depths, still in use by those who have left the waters. Known to those devout to Abyssor, for they have studied it."
	speech_verb = "says"
	ask_verb = "ponders"
	exclaim_verb = "yells"
	key = "a"
	flags = LANGUAGE_HIDE_ICON_IF_UNDERSTOOD | LANGUAGE_HIDE_ICON_IF_NOT_UNDERSTOOD
	space_chance = 60
	default_priority = 90
	icon_state = "asse"
	spans = list(SPAN_ABYSSAL)
	syllables = list(
//		"ho", "ogdo", "doos", "kos", "on", "poria", "odyr", "oike", "poteo", "tes", "ope",
//		"thias", "kos", "mar", "mai", "nema", "mes", "axy", "tes", "dosia", "osis", "kia",
		"&iota;ζω", "&lambda;ος", "ος", "&alpha;ῦ", "&delta;αιμ", "&tau;ής", "&alpha;σ", "&phi;ω", "&alpha;κ", "&mu;ος", "&eta;σσ",
		"&alpha;φι", "&alpha;φο", "&omicron;δ", "&kappa;ια", "&omicron;π", "&omega;σις", "&omicron;ία", "&omicron;ρμ", "&rho;οθε", "&pi;οτ", "&omicron;ὐρ", "&lambda;μο",
		"&nu;έω", "&delta;ει", "&rho;ες", "&delta;εξ", "&beta;ος", "τερα", "&gamma;αβ", "&gamma;άζα", "&iota;ζω", "&gamma;έν", "&nu;άω", "&rho;ίζω", "&gamma;όμ",
		"&omicron;ς", "&omicron;ία", "&gamma;ων", "&epsilon;ύλ", "&omicron;χέω", "&epsilon;υρ", "&alpha;ω", "&omega;σις", "&tau;άφ", "&iota;ον", "&tau;ελ", "&epsilon;ίως", "&nu;τα",
		"&tau;εσσερ", "&theta;ημι", "&tau;ίμ", "&tau;ις", "&gamma;ος", "&tau;ρῆ", "&nu;ἱο", "&iota;ός", "&omicron;τίθ", "&psi;ηλο", "&mu;ψωμα", "&kappa;ει")
//		"ett", "est", "ozio", "ozia", "non", "gli", "chi", "noc", "gno", "enti", "att", "olo",
//		"anc", "gogna", "esto", "ll", "ost")
