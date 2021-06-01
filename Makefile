include colors.mk
TRG=repos
CMD=repos
version = 0.1.0
arch = all
ssm_package = repos_$(version)_$(arch)
ssm_auto_sourced_file = ${ssm_package}/etc/profile.d/${ssm_package}.sh

SSMD_PREFIX ?= $(PWD)


PREFIX ?= /usr

all:$(TRG)

$(TRG):main.go
	$(call make_echo_generate_file)
	$(at) go build
	true

test:$(TRG)
	$(call make_echo_run_test,"Running $<")
	$(at) ./repos

../repos-$(version).tar.gz:
	$(call make_echo_color_bold,blue,Initializing debian package with debmake)
	$(at) rm -f $@
	$(at) tar -zcf $@ .
	$(at) debmake
deb:../repos-$(version).tar.gz
	$(call make_echo_color_bold,blue,Creating debian package with debuild)
	$(at) debuild --no-lintian -us -uc

debclean:
	$(at) rm -f ../repos-$(version).tar.gz

$(ssm_package)/.ssm.d/control.json: scripts/make_ssm_control_file.py Makefile
	$(call make_echo_generate_file)
	$(at) mkdir -p $(shell dirname $@)
	$(at) python3 $< --version $(version) --name repos --summary "Repos CLI tool" --description "Repos command line tool" > $@
$(ssm_auto_sourced_file): Makefile
	$(call make_echo_generate_file)
	$(at) mkdir -p $(shell dirname $@)
	$(at) ln -s ../repos_completion.bash $@

ssm:$(ssm_package).ssm

$(ssm_package).ssm:
	$(call make_echo_generate_file)
	$(at) make PREFIX=$(PWD)/$(ssm_package) install
	$(at) make $(ssm_package)/.ssm.d/control.json
	$(at) make $(ssm_auto_sourced_file)
	$(at) tar -cvf $@ $(ssm_package)

install:$(TRG)
	install -D repos $(DESTDIR)$(PREFIX)/bin/repos
	install -D man/man1/repos.man $(DESTDIR)$(PREFIX)/share/man/man1/repos.1
	install -D scripts/git-recent $(DESTDIR)$(PREFIX)/bin/git-recent
	install -D --mode 644 completions/repos_completion.bash $(DESTDIR)$(PREFIX)/etc/repos_completion.bash
	install -D --mode 644 completions/repos_completion.fish $(DESTDIR)$(PREFIX)/etc/repos_completion.fish
	install -D --mode 644 completions/repos_completion.zsh  $(DESTDIR)$(PREFIX)/etc/repos_completion.zsh

clean:
	rm -f *.ssm
	rm -rf repos_*_all
	rm -rf repos.ssmd

dist:$(TRG)
	go build
	cp $(TRG) ~/.local/bin/$(CMD)
	GOOS=linux go build
	scp $(TRG) ppp4:~/.local/bin/$(CMD)
