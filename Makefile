#!/usr/bin/make -f

package=mythtv-status
releases=etch sid
sponsor_keyid=19D03486

build=dpkg-buildpackage -sn -uc -us -rfakeroot -i'(.git|build|.gitignore)*' -I.git -Ibuild -I.gitignore
version=$(shell git-tag -l | grep -v ^debian | tail -1)

deb=$(package)_$(version)-1_all.deb
orig_tarball=../$(package)_$(version).orig.tar.gz
tarball=build/tarball/$(package)-$(version).tar.gz
tarball_dir=../$(package)_tarballs

DEBS=$(foreach release, $(releases), build/$(release)/$(deb))

RELEASE_FILES=build/tarball/mythtv-status-${version}.tar.gz $(DEBS)

all: release

release: $(RELEASE_FILES)

$(orig_tarball): $(tarball)
	@rm -f $@
	@ln -s `basename \`pwd\``/$< $@

sponsor: $(orig_tarball)
	dpkg-buildpackage -rfakeroot -k$(sponsor_keyid) -i'(.git|build|Makefile)' -tc

$(tarball):
	@mkdir -p $(@D)
	@git-archive --format=tar --prefix=$(package)-$(version)/ $(version) `git-ls-tree --name-only $(version) | egrep -v "(.gitignore|debian|Makefile)"` | gzip > $(tarball)

build/etch/$(deb): 
	@ssh build-etch-i386 "cd `pwd`; $(build)"
	@ssh build-etch-i386 "cd `pwd`/..; /usr/bin/lintian -i $(package)_$(version)*.changes"
	@ssh build-etch-i386 "cd `pwd`/..; /usr/bin/linda -i $(package)_$(version)*.changes"
	@mkdir -p build/etch
	@mv ../$(deb) build/etch

build/sid/$(deb): 
	@ssh build-sid-i386 "cd `pwd`; $(build)"
	@ssh build-sid-i386 "cd `pwd`/..; /usr/bin/lintian -i $(package)_$(version)*.changes"
	@ssh build-sid-i386 "cd `pwd`/..; /usr/bin/linda -i $(package)_$(version)*.changes"
	@mkdir -p build/sid
	@mv ../$(deb) build/sid

publish: $(RELEASE_FILES)
	for release in $(releases); do ars-add -r $$release -g main build/$$release/$(deb); done
	@ars-update -f
	@cp $(tarball) $(tarball_dir)
	@chmod o+r $(tarball_dir)/*-$(version).*
	@ln -sf `basename $(tarball)` $(tarball_dir)/$(package)-latest.tar.gz

clean:
	@rm -rf build

.PHONY: release clean sponsor
