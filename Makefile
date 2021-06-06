include util/colors.mk

PREFIX ?= $(PWD)/localinstall
TRG=repos

version = 0.1.0

ifeq ($(shell uname),Darwin)
	# If you are on a mac with ginstall, 'brew install coreutils'
	INSTALL=ginstall
else
	INSTALL=install
endif

all:$(TRG) man

#
# Regular targets
#
$(TRG):src/main.go
	$(call make_echo_generate_file)
	$(at) cd src && go build -o $(PWD)/$@

test:$(TRG)
	$(call make_echo_run_test,"Running $<")
	$(at) ./$(TRG)

man: share/man/man1/repos.1 share/man/man1/rcd.1

%.man:%.org
	emacs --batch -l ox-man $< -f org-man-export-to-man
%.1:%.man
	mv $< $@

install: $(TRG) man
	$(call make_echo_color_bold,cyan,Installing project to $(DESTDIR)$(PREFIX))
	$(INSTALL) -D repos $(DESTDIR)$(PREFIX)/bin/repos
	$(INSTALL) -D share/man/man1/repos.1 $(DESTDIR)$(PREFIX)/share/man/man1/repos.1
	$(INSTALL) -D share/man/man1/rcd.1 $(DESTDIR)$(PREFIX)/share/man/man1/rcd.1
	$(INSTALL) -D scripts/git-recent $(DESTDIR)$(PREFIX)/bin/git-recent
	$(INSTALL) -D scripts/repo_finder.py $(DESTDIR)$(PREFIX)/bin/repo-finder
	$(INSTALL) -D --mode 644 completions/repos_completion.bash $(DESTDIR)$(PREFIX)/etc/repos_completion.bash
	$(INSTALL) -D --mode 644 completions/repos_completion.fish $(DESTDIR)$(PREFIX)/etc/repos_completion.fish
	$(INSTALL) -D --mode 644 completions/repos_completion.zsh  $(DESTDIR)$(PREFIX)/etc/repos_completion.zsh
	@printf "\033[1;35mRepo installed to $(PWD)/localinstall for trial use\n"
	@printf "\033[1;35m$@: Extra instructions to use local install\033[0m\n"
	@printf "\033[1;33mAdd the following to your PATH environment variable\033[0m\n"
	@printf "\n\t$(PWD)/localinstall/bin\n\n"
	@printf "\033[1;33mAdd this to your BASH startup file\033[0m\n"
	@printf "\n\t$(PWD)/localinstall/etc/repos_completion.bash\n\n"
	@printf "\033[1;33mAdd this to your FISH startup file\033[0m\n"
	@printf "\n\t$(PWD)/localinstall/etc/repos_completion.fish\n\n"
	@printf "\033[1;33mAdd this to your ZSH startup file\033[0m\n"
	@printf "\n\t$(PWD)/localinstall/etc/repos_completion.zsh\n\n"


# NOTE:I don't use variables with 'rm -rf' in makefiles
clean:
	rm -f share/man/man1/*.1
	rm -f *.ssm
	rm -f $(TRG)
	rm -rf repos_*_all
	rm -rf repos.ssmd

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
