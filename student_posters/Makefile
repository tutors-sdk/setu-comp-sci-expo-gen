# student_posters

EDITED = ${wildcard edited/*.jpeg}
RES_EBOOK = ${subst edited/,res_ebook/, ${EDITED}}
RES_PRINT = ${subst edited/,res_print/, ${EDITED}}

edited/%.jpeg: orig/%.jpeg
	cp $< $@
res_ebook/%.jpeg: edited/%.jpeg
	sips --resampleWidth 250 $< --out $@

res_print/%.jpeg: edited/%.jpeg
	sips --resampleWidth 600 $< --out $@

# alternatively we have poster directly downloaded from Moodle and we need to convert them to jpeg
PDF =${wildcard pdf/*.pdf} 
JPEG = ${subst .pdf,.jpeg,${subst pdf/,jpeg/, ${PDF}}}

jpeg/%.jpeg: pdf/%.pdf
	sips -s format jpeg -s formatOptions 80 $< --out $@

build: ${EDITED} res_ebook res_print ${JPEG}

clean: 
	rm -f ${RES_EBOOK} ${RES_PRINT} ${JPEG}
	
reset: clean
	rm -f ${EDITED} ${PDF}

res_ebook: ${RES_EBOOK}

res_print: ${RES_PRINT}

dev:
	echo ${RES_EBOOK}

