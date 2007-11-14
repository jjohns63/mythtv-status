#!/usr/bin/make -f

package=mythtv-status
releases=etch sid

build=dpkg-buildpackage -uc -us -rfakeroot
version=`git-tag -l | head -1`

deb=$(package)_$(version)_all.deb
tarball=build/tarball/$(package)-$(version).tar.gz

DEBS=$(foreach release, $(release), build/$(release)/$(deb))

release: build/tarball/mythtv-status-${version}.tar.gz etch-i386 sid-i386

all: $(tarball) $(DEBS)

$(tarball):
	mkdir -p $(@D)
	git-archive --format=tar $(version) | gzip > $(tarball)

etch-i386:
	ssh build-etch-i386 "cd `pwd`; $(build)"
	@mkdir -p build/etch
	@mv ../$(deb) build/etch

sid-i386:
	ssh build-sid-i386 "cd `pwd`; $(build)"
	@mkdir -p build/sid
	@mv ../$(deb) build/sid

.PHONY: release etch-i386 sid-i386
