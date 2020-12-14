TRG=repo-manager
CMD=repos

all:$(TRG)

$(TRG):main.go
	go build
test:$(TRG)
	./repo-manager

dist:$(TRG)
	go build
	cp $(TRG) ~/.local/bin/$(CMD)
	GOOS=linux go build
	scp $(TRG) ppp4:~/.local/bin/$(CMD)
