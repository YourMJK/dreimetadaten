DIR = bin
SWIFTBUILD = swift build --package-path code -c release --product
BINARIES = code/.build/release

.PHONY: dreimetadaten all clean distclean
.DEFAULT_GOAL := all


$(DIR):
	mkdir $(DIR)

dreimetadaten:
	$(SWIFTBUILD) dreimetadaten


all: $(DIR) dreimetadaten
	@cp -v $(BINARIES)/dreimetadaten $(DIR)/

clean:
	swift package clean --package-path code
	rm -f $(DIR)/dreimetadaten

distclean: clean
	rm -f code/Package.resolved
