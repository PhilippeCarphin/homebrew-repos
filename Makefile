include colors.mk

PREFIX ?= /usr
TRG=repos

version = 0.1.0

# SSM package configuration
arch = all
ssm_package = repos_$(version)_$(arch)
ssm_auto_sourced_file = ${ssm_package}/etc/profile.d/${ssm_package}.sh

ifeq ($(shell uname),Darwin)
	# If you are on a mac with ginstall, 'brew install coreutils'
	INSTALL=ginstall
else
	INSTALL=install
endif

all:$(TRG)

#
# Regular targets
#
$(TRG):main.go
	$(call make_echo_generate_file)
	$(at) go build

test:$(TRG)
	$(call make_echo_run_test,"Running $<")
	$(at) ./repos

install: $(TRG)
	$(call make_echo_color_bold,cyan,Installing project)
	$(INSTALL) -D repos $(DESTDIR)$(PREFIX)/bin/repos
	$(INSTALL) -D man/man1/repos.man $(DESTDIR)$(PREFIX)/share/man/man1/repos.1
	$(INSTALL) -D scripts/git-recent $(DESTDIR)$(PREFIX)/bin/git-recent
	$(INSTALL) -D --mode 644 completions/repos_completion.bash $(DESTDIR)$(PREFIX)/etc/repos_completion.bash
	$(INSTALL) -D --mode 644 completions/repos_completion.fish $(DESTDIR)$(PREFIX)/etc/repos_completion.fish
	$(INSTALL) -D --mode 644 completions/repos_completion.zsh  $(DESTDIR)$(PREFIX)/etc/repos_completion.zsh

# NOTE:I don't use variables with 'rm -rf' in makefiles
clean:
	rm -f *.ssm
	rm -f $(TRG)
	rm -rf repos_*_all
	rm -rf repos.ssmd

#
# Debian package
#
deb:../repos-$(version).tar.gz
	$(call make_echo_color_bold,blue,Creating debian package with debuild)
	$(at) debuild --no-lintian -us -uc
../repos-$(version).tar.gz:
	$(call make_echo_color_bold,blue,Initializing debian package with debmake)
	$(at) rm -f $@
	$(at) tar -zcf $@ .
	$(at) debmake
debclean:
	$(at) rm -f ../repos-$(version).tar.gz

#
# SSM package
# - $(ssm_package) is the directory
# - $(ssm_package).ssm is the tar archive
#
ssm:$(ssm_package).ssm
$(ssm_package)/.ssm.d/control.json: scripts/make_ssm_control_file.py Makefile
	$(call make_echo_generate_file)
	$(at) mkdir -p $(shell dirname $@)
	$(at) python3 $< --version $(version) --name repos --summary "Repos CLI tool" --description "Repos command line tool" > $@
$(ssm_auto_sourced_file): Makefile
	$(call make_echo_generate_file)
	$(at) mkdir -p $(shell dirname $@)
	$(at) ln -s ../repos_completion.bash $@
$(ssm_package):
	$(call make_echo_generate_file)
	$(at) make --no-print-directory PREFIX=$(PWD)/$(ssm_package) install
	$(at) make --no-print-directory $(ssm_package)/.ssm.d/control.json
	$(at) make --no-print-directory $(ssm_auto_sourced_file)
$(ssm_package).ssm: $(ssm_package)
	$(call make_echo_color_bold,green,Building ssm package $@)
	$(at) tar -cf $@ $(ssm_package)

