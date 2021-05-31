TRG=repos
CMD=repos

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

install:$(TRG)
	install -D repos $(DESTDIR)$(PREFIX)/bin/repos
	install -D scripts/git-recent $(DESTDIR)$(PREFIX)/bin/git-recent
	install -D completions/repos_completion.bash $(DESTDIR)$(PREFIX)/etc/repos_completion.bash

dist:$(TRG)
	go build
	cp $(TRG) ~/.local/bin/$(CMD)
	GOOS=linux go build
	scp $(TRG) ppp4:~/.local/bin/$(CMD)
