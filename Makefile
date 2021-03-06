ifeq ($(SCIDB),) 
  X := $(shell which scidb 2>/dev/null)
  ifneq ($(X),)
    X := $(shell dirname ${X})
    SCIDB := $(shell dirname ${X})
  endif
endif
GIT_VERSION := $(shell git describe --abbrev=4 --dirty --always)

CFLAGS=-fopenmp -g -DVERSION=\"$(GIT_VERSION)\"
INC=-I. -DPROJECT_ROOT="\"$(SCIDB)\"" -I"$(SCIDB)/3rdparty/boost/include/" -I"$(SCIDB)/include" -DSCIDB_CLIENT
LIBS=-ldl -lz -lpthread -L"$(SCIDB)/3rdparty/boost/lib" -L"$(SCIDB)/lib" -lscidbclient -lboost_system -lpam -Wl,-rpath,$(SCIDB)/lib:$(RPATH)
# default: empty DESTDIR implicitly installs to /
DESTDIR=

shim: pam client
	$(CC) -std=c99 -Wall $(CFLAGS) -DUSE_WEBSOCKET $(INC) $(LDFLAGS) -fpic -g -o shim shim.c mongoose.c client.o pam.o $(LIBS)

client:
	$(CXX) $(CXXFLAGS) $(INC) -fpic -g -c client.cpp -o client.o

pam:
	$(CC) -Wall $(CFLAGS) -fpic -g -c pam.c -o pam.o

help:
	@echo "make shim      (compile and link)"
	@echo
	@echo "The remaining options may require setting the SCIDB environment"
	@echo "variable to the path of the target SciDB installation. For example,"
	@echo "make SCIDB=/opt/scidb/13.3  install"
	@echo
	@echo "make install   (install program and files)"
	@echo "make uninstall (remove program and files)"
	@echo "make service   (install a Debian or RHEL init.d-style service, shimsvc)"
	@echo "make unservice (terminate and remove installed service)"
	@echo "make deb-pkg   (create a binary Ubuntu/Debian package, requires fpm)"
	@echo "make rpm-pkg   (create a binary RHEL package, requires fpm)"

install: shim
	@if test ! -d "$(SCIDB)"; then echo  "Can't find scidb. Maybe try explicitly setting SCIDB variable, for example::\n\nmake SCIDB=/opt/scidb/13.3 install"; exit 1; fi 
	@if test -x /etc/init.d/shimsvc; then /etc/init.d/shimsvc stop;fi
	mkdir -p "$(DESTDIR)$(SCIDB)/bin"
	cp shim "$(DESTDIR)/$(SCIDB)/bin"
	mkdir -p "$(DESTDIR)/var/lib/shim"
	cp -aR wwwroot "$(DESTDIR)/var/lib/shim/"
	chmod -R 755 "$(DESTDIR)/var/lib/shim"
	@if test -d $(DESTDIR)/usr/local/share/man/man1;then cp man/shim.1 $(DESTDIR)/usr/local/share/man/man1/;fi

uninstall: unservice
	@if test ! -d "$(SCIDB)"; then echo  "Can't find scidb. Maybe try explicitly setting SCIDB variable, for example:\n\nmake SCIDB=/opt/scidb/13.3 uninstall"; exit 1; fi 
	- @if test -x /etc/init.d/shimsvc; then /etc/init.d/shimsvc stop;fi
	rm -f "$(SCIDB)/bin/shim"
	rm -rf /var/lib/shim
	rm -f /usr/local/share/man/man1/shim.1

service: install
	cp init.d/shimsvc /etc/init.d
	chmod 0755 /etc/init.d/shimsvc
	@if test -n "$$(which update-rc.d 2>/dev/null)"; then update-rc.d shimsvc defaults;fi
	@if test -n "$$(which chkconfig 2>/dev/null)"; then chkconfig --add shimsvc && chkconfig shimsvc on;fi
	/etc/init.d/shimsvc start

unservice:
	@if test -f /etc/init.d/shimsvc; then /etc/init.d/shimsvc stop; fi
	- @if test -n "$$(which update-rc.d 2>/dev/null)"; then sudo update-rc.d -f shimsvc remove;fi
	- @if test -n "$$(which chkconfig 2>/dev/null)"; then chkconfig --del shimsvc;fi
	rm -rf /etc/init.d/shimsvc

deb-pkg: shim
	@if test -z "$$(which fpm 2>/dev/null)"; then echo "Error: Package building requires fpm, try running gem install fpm."; exit 1;fi
	@if test ! -d "$(SCIDB)"; then echo  "Can't find scidb. Maybe try explicitly setting SCIDB variable, for example::\n\nmake SCIDB=/opt/scidb/13.3 install"; exit 1; fi 
	mkdir -p pkgroot/$(SCIDB)/bin
	cp shim "pkgroot/$(SCIDB)/bin"
	mkdir -p pkgroot/etc/init.d
	cp init.d/shimsvc pkgroot/etc/init.d
	mkdir -p pkgroot/var/lib/shim
	cp -aR wwwroot pkgroot/var/lib/shim/
	chmod -R 755 pkgroot/var/lib/shim
	mkdir -p pkgroot/usr/local/share/man/man1
	@if test -d /usr/local/share/man/man1;then cp man/shim.1 pkgroot/usr/local/share/man/man1/;fi
	fpm -s dir -t deb -n shim --vendor Paradigm4 -d libssl-dev --license AGPLv3 -m "<blewis@paradigm4.com>" --url "https://github.com/Paradigm4/shim" --description "Unofficial SciDB HTTP service" --provides "shim" -v $$(basename $(SCIDB)) --after-install init.d/after-install.sh --before-remove init.d/before-remove.sh -C pkgroot opt usr var etc/init.d

rpm-pkg: shim
	@if test -z "$$(which fpm 2>/dev/null)"; then echo "Error: Package building requires fpm, try running gem install fpm."; exit 1;fi
	@if test ! -d "$(SCIDB)"; then echo  "Can't find scidb. Maybe try explicitly setting SCIDB variable, for example::\n\nmake SCIDB=/opt/scidb/13.3 install"; exit 1; fi 
	mkdir -p pkgroot/$(SCIDB)/bin
	cp shim "pkgroot/$(SCIDB)/bin"
	mkdir -p pkgroot/etc/init.d
	cp init.d/shimsvc pkgroot/etc/init.d
	mkdir -p pkgroot/var/lib/shim
	cp -aR wwwroot pkgroot/var/lib/shim/
	chmod -R 755 pkgroot/var/lib/shim
	mkdir -p pkgroot/usr/local/share/man/man1
	@if test -d /usr/local/share/man/man1;then cp man/shim.1 pkgroot/usr/local/share/man/man1/;fi
	fpm -s dir -t rpm -n shim -d "openssl-devel" --vendor Paradigm4 --license AGPLv3 -m "<blewis@paradigm4.com>" --url "https://github.com/Paradigm4/shim" --description "Unofficial SciDB HTTP service" --provides "shim" -v $$(basename $(SCIDB)) --after-install init.d/after-install.sh --before-remove init.d/before-remove.sh -C pkgroot opt usr var etc/init.d

clean:
	rm -fr *.o *.so shim pkgroot *.rpm *.deb


test1: shim
	@echo "Non-authenticated test"
	@LD_LIBRARY_PATH="$(SCIDB)/3rdparty/boost/lib" ./tests/noauth.sh

test2: shim
	@echo "Basic digest authentication"
	@LD_LIBRARY_PATH="$(SCIDB)/3rdparty/boost/lib" ./tests/digest_auth.sh

test3: shim
	@echo "TLS without authentication"
	@LD_LIBRARY_PATH="$(SCIDB)/3rdparty/boost/lib" ./tests/tls.sh

test4: shim
	@echo "TLS with digest authentication"
	@LD_LIBRARY_PATH="$(SCIDB)/3rdparty/boost/lib" ./tests/tls_digest.sh

test5: shim
	@echo "Streaming"
	@LD_LIBRARY_PATH="$(SCIDB)/3rdparty/boost/lib" ./tests/stream.sh

test6: shim
	@echo "Streaming with compression"
	@LD_LIBRARY_PATH="$(SCIDB)/3rdparty/boost/lib" ./tests/compressed_stream.sh

test7: shim
	@echo "multiuser streaming test"
	@LD_LIBRARY_PATH="$(SCIDB)/3rdparty/boost/lib" ./tests/multiple_users_stream.sh

alltests: test1 test2 test3 test4 test5 test6 test7
