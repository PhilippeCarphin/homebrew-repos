TRG=repos
CMD=repos

all:$(TRG)

$(TRG):main.go
	true
test:$(TRG)
	./repos

install:$(TRG)
	install -D repos $(DESTDIR)$(PREFIX)/bin/repos
	install -D scripts/git-recent $(DESTDIR)$(PREFIX)/bin/git-recent
	install -D completions/repos_completion.bash $(DESTDIR)$(PREFIX)/etc/bash_completion/repos_completion.bash

dist:$(TRG)
	go build
	cp $(TRG) ~/.local/bin/$(CMD)
	GOOS=linux go build
	scp $(TRG) ppp4:~/.local/bin/$(CMD)
