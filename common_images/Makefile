# common_images
# orig, edited, res_print, res_ebook 

ORIG = $(wildcard orig/*.pdf) $(wildcard orig/*.png) $(wildcard orig/*.jpg) $(wildcard orig/*.jpeg)
EDITED = $(subst orig/,edited/,$(ORIG))
RES_PRINT = $(subst orig/,res_print/,$(ORIG))
RES_EBOOK = $(subst orig/,res_ebook/,$(ORIG))

build: $(EDITED) $(RES_PRINT) $(RES_EBOOK)
	
clean: 
	rm -f ${RES_EBOOK} ${RES_PRINT} ${RES_COLM}

reset: clean
	rm -f ${EDITED} ${ORIG}

# edited <- orig = just a copy now
edited/%.pdf: orig/%.pdf
	cp $< $@
edited/%.png: orig/%.png
	cp $< $@	
edited/%.jpg: orig/%.jpg
	cp $< $@
edited/%.jpeg: orig/%.jpeg
	cp $< $@

res_print/%.pdf: edited/%.pdf
	cp $< $@
res_print/%.png: edited/%.png
	cp $< $@
res_print/%.jpg: edited/%.jpg
	cp $< $@
res_print/%.jpeg: edited/%.jpeg
	cp $< $@

res_ebook/%.pdf: edited/%.pdf
	cp $< $@
res_ebook/%.png: edited/%.png
	sips --resampleWidth 256 $< --out $@
res_ebook/%.jpg: edited/%.jpg
	sips --resampleWidth 256 $< --out $@
res_ebook/%.jpeg: edited/%.jpeg
	sips --resampleWidth 256 $< --out $@
