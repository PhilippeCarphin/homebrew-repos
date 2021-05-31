TRG=repos
CMD=repos

PREFIX ?= /usr

all:$(TRG)

$(TRG):main.go
	true
test:$(TRG)
	./repos

../repos-0.1.0.tar.gz:
	rm -f $@
	tar -zcf $@ .
	debmake
deb:../repos-0.1.0.tar.gz
	debuild --no-lintian -us -uc

debclean:
	rm -f ../repos-0.1.0.tar.gz

install:$(TRG)
	install -D repos $(DESTDIR)$(PREFIX)/bin/repos
	install -D man/man1/repos.man $(DESTDIR)$(PREFIX)/share/man/man1/repos.1
	install -D scripts/git-recent $(DESTDIR)$(PREFIX)/bin/git-recent
	install -D completions/repos_completion.bash $(DESTDIR)$(PREFIX)/etc/repos_completion.bash

dist:$(TRG)
	go build
	cp $(TRG) ~/.local/bin/$(CMD)
	GOOS=linux go build
	scp $(TRG) ppp4:~/.local/bin/$(CMD)
