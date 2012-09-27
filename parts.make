refresh:
	PERLLIB=$(PO4ALIB) $(PO4A) -f --keep 0 "po/introduction.conf"
	PERLLIB=$(PO4ALIB) $(PO4A) -f --keep 0 "po/qanda.conf"
