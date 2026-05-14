# student_images

EDITED = ${wildcard edited/*.jpeg}
RES_EBOOK = ${subst edited/,res_ebook/, ${EDITED}}
RES_PRINT = ${subst edited/,res_print/, ${EDITED}}
RES_COLM = ${subst edited/,res_colm/, ${EDITED}}

res_ebook/%.jpeg: edited/%.jpeg
	sips --resampleWidth 250 $< --out $@

res_print/%.jpeg: edited/%.jpeg
	sips --resampleWidth 600 $< --out $@

res_colm/%.jpeg: edited/%.jpeg
	sips --resampleWidth 1200 $< --out $@

build: res_ebook res_print res_colm

clean: 
	rm -f ${RES_EBOOK} ${RES_PRINT} ${RES_COLM}

reset: clean
	rm -f ${EDITED} 

res_ebook: ${RES_EBOOK}
res_print: ${RES_PRINT}
res_colm: ${RES_COLM}
		
dev:
	echo ${RES_EBOOK}

