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
man_1_src = $(wildcard share/man/man1/*.org)
man_1 = $(man_1_src:.org=.1)
man: $(man_1)
	@echo "man_1_src = $(man_1_src)"
	@echo "man_1 = $(man_1)"

%.man:%.org
	emacs --batch -l ox-man $< -f org-man-export-to-man
%.1:%.man
	mv $< $@

install: $(TRG) man
	$(call make_echo_color_bold,cyan,Installing project to $(DESTDIR)$(PREFIX))
	$(INSTALL) -D repos $(DESTDIR)$(PREFIX)/bin/repos
	@for f in $(man_1) ; do \
		echo $(INSTALL) -D $$f $(DESTDIR)$(PREFIX)/$$f ;\
		$(INSTALL) -D $$f $(DESTDIR)$(PREFIX)/$$f ;\
	done
	$(INSTALL) -D scripts/git-recent $(DESTDIR)$(PREFIX)/bin/git-recent
	$(INSTALL) -D scripts/repo_finder.py $(DESTDIR)$(PREFIX)/bin/repo-finder
	$(INSTALL) -D --mode 644 completions/repos_completion.bash $(DESTDIR)$(PREFIX)/etc/bash_completion.d/repos_completion.bash
	$(INSTALL) -D --mode 644 completions/repos_completion.fish $(DESTDIR)$(PREFIX)/etc/fish/vendor_completions.d/repos_completion.fish
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
	rm -f *.ssm
	rm -f $(TRG)
	rm -rf repos_*_all
	rm -rf repos.ssmd

# I leave it separate because I decided to package the generated files with the
# repos since not everybody has emacs or pandoc setup.
cleanman:
	rm -f share/man/man1/*.1
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
