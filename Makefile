include colors.mk
TRG=repos
CMD=repos

PREFIX ?= /usr

all:$(TRG)

$(TRG):main.go
	$(call make_echo_generate_file)
	$(at) go build
	true

test:$(TRG)
	$(call make_echo_run_test,"Running $<")
	$(at) ./repos

../repos-0.1.0.tar.gz:
	$(call make_echo_color_bold,blue,Initializing debian package with debmake)
	$(at) rm -f $@
	$(at) tar -zcf $@ .
	$(at) debmake
deb:../repos-0.1.0.tar.gz
	$(call make_echo_color_bold,blue,Creating debian package with debuild)
	$(at) debuild --no-lintian -us -uc

debclean:
	$(at) rm -f ../repos-0.1.0.tar.gz

install:$(TRG)
	install -D repos $(DESTDIR)$(PREFIX)/bin/repos
	install -D man/man1/repos.man $(DESTDIR)$(PREFIX)/share/man/man1/repos.1
	install -D scripts/git-recent $(DESTDIR)$(PREFIX)/bin/git-recent
	install -D --mode 644 completions/repos_completion.bash $(DESTDIR)$(PREFIX)/etc/repos_completion.bash
	install -D --mode 644 completions/repos_completion.fish $(DESTDIR)$(PREFIX)/etc/repos_completion.fish
	install -D --mode 644 completions/repos_completion.zsh  $(DESTDIR)$(PREFIX)/etc/repos_completion.zsh

dist:$(TRG)
	go build
	cp $(TRG) ~/.local/bin/$(CMD)
	GOOS=linux go build
	scp $(TRG) ppp4:~/.local/bin/$(CMD)
