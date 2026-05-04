PAPER := paper.typ
PDF   := paper.pdf
ROOT  := ..

.PHONY: all watch clean

all: $(PDF)

$(PDF): $(PAPER) template.typ references.yml
	typst compile --root $(ROOT) $(PAPER)

watch:
	typst watch --root $(ROOT) $(PAPER)

clean:
	rm -f $(PDF)
