#!/usr/bin/make -f

package=mythtv-status
releases=etch sid

build=dpkg-buildpackage -uc -us -rfakeroot
version=$(shell git-tag -l | tail -1)

deb=$(package)_$(version)_all.deb
tarball=build/tarball/$(package)-$(version).tar.gz
tarball_dir=../$(package)_tarballs

DEBS=$(foreach release, $(releases), build/$(release)/$(deb))

RELEASE_FILES=build/tarball/mythtv-status-${version}.tar.gz $(DEBS)

all: release

release: $(RELEASE_FILES)

$(tarball):
	@mkdir -p $(@D)
	@git-archive --format=tar $(version) `git-ls-tree --name-only $(version) | egrep -v "(.gitignore|debian|Makefile)"` | gzip > $(tarball)

build/etch/$(deb): 
	@ssh build-etch-i386 "cd `pwd`; $(build)"
	@mkdir -p build/etch
	@mv ../$(deb) build/etch

build/sid/$(deb): 
	@ssh build-sid-i386 "cd `pwd`; $(build)"
	@mkdir -p build/sid
	@mv ../$(deb) build/sid

publish: $(RELEASE_FILES)
	for release in $(releases); do ars-add -r $$release -g main build/$$release/$(deb); done
	@cp $(tarball) $(tarball_dir)
	@chmod o+r $(tarball_dir)/*-$(version).*
	@ln -sf `basename $(tarball)` $(tarball_dir)/$(package)-latest.tar.gz

clean:
	@rm -rf build

.PHONY: release clean
