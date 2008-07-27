#!/usr/bin/make -f

package=mythtv-status
releases=sid
sponsor_keyid=19D03486

build=dpkg-buildpackage -sn -uc -us -rfakeroot -i'(.git|build|.gitignore|testing)*' -I.git -Ibuild -I.gitignore -Itesting
version=$(shell git-tag -l | grep '^[0-9]' | tail -1)
deb_version=$(shell git-tag -l | grep ^debian-[[:digit:]] | tail -1 | sed 's/debian-//')

deb=$(package)_$(deb_version)_all.deb
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
	dpkg-buildpackage -rfakeroot -k$(sponsor_keyid) -i'(.git|build|Makefile|testing)' -I.git -IMakefile -I.gitignore -Ibuild -Itesting -tc

$(tarball):
	@mkdir -p $(@D)
	@git-archive --format=tar --prefix=$(package)-$(version)/ $(version) `git-ls-tree --name-only $(version) | egrep -v "(.gitignore|debian|Makefile|testing)"` | gzip > $(tarball)

build/etch/$(deb): 
	@echo Building Etch
	@ssh build-etch-i386 "cd `pwd`; DH_COMPAT=5 $(build) -d"
	@ssh build-etch-i386 "cd `pwd`/..; /usr/bin/lintian -i -I $(package)_$(version)*.changes" || true
	@ssh build-etch-i386 "cd `pwd`/..; /usr/bin/linda -i $(package)_$(version)*.changes" || true
	@mkdir -p build/etch
	@cp ../$(deb) build/etch

build/sid/$(deb): 
	@echo Building Sid
	@ssh build-sid-i386 "cd `pwd`; $(build)"
	@ssh build-sid-i386 "cd `pwd`/..; /usr/bin/lintian -i -I $(package)_$(version)*.changes" || true
	@ssh build-sid-i386 "cd `pwd`/..; /usr/bin/linda -i $(package)_$(version)*.changes" || true
	@mkdir -p build/sid
	@cp ../$(deb) build/sid

publish: $(RELEASE_FILES)
	for release in $(releases); do ars-add -r $$release -g main build/$$release/$(deb); done
	@ars-update -f
	@cp $(tarball) $(tarball_dir)
	@chmod o+r $(tarball_dir)/*-$(version).*
	@ln -sf `basename $(tarball)` $(tarball_dir)/$(package)-latest.tar.gz

clean:
	@rm -rf build
	@rm -f ../$(package)*.changes ../$(package)*.dsc ../$(package)*.tar.gz ../$(package)*.deb

.PHONY: release clean sponsor
