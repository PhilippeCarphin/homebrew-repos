package main

import (
	"flag"
	"fmt"
	"time"

	"os"
	"os/exec"

	"io/ioutil"

	"gopkg.in/yaml.v2"
)

// RepoFile sucks
type RepoFile struct {
	Repos map[string]repoConfig
	Config config
}
type args struct {
	command        string
	path           string
	name           string
	generateConfig bool
}

func getArgs() args {

	var a args

	a.command = flag.Arg(0)
	flag.StringVar(&a.path, "path", "/a/path/", "Path of repo")
	flag.BoolVar(&a.generateConfig, "generate-config", false, "")
	flag.Parse()

	return a
}

type config struct {
	Color    bool
	Defaults repoConfig
}

type repoConfig struct {
	Path      string
	Name      string
	ShortName string
	Fetch bool
}

type repoInfo struct {
	Config repoConfig
	State  repoState
}

type repoState struct {
	Dirty               bool
	UntrackedFiles      bool
	TimeSinceLastCommit time.Time
}

type repos []repoConfig

func (r repoConfig) gitCommand(args ...string) *exec.Cmd {
	cmd := exec.Command("git", args...)
	cmd.Stderr = os.Stderr
	cmd.Dir = r.Path
	return cmd
}

func (r *repoConfig) hasUnstagedChanges() bool {
	cmd := r.gitCommand("diff", "--no-ext-diff", "--quiet", "--exit-code")
	err := cmd.Run()
	if err != nil {
		panic(err)
	}
	return cmd.ProcessState.Success()
}

func (r *repoConfig) hasUntrackedFiles() bool {
	cmd := r.gitCommand("ls-files", r.Path, "--others", "--exclude-standard")
	out, err := cmd.Output()
	if err != nil {
		panic(err)
	}
	return len(out) != 0
}
func dumpDatabase(filename string, database []*repoInfo) {
	repos := make(map[string]repoConfig, len(database))
	for _, ri := range database {
		repos[ri.Config.Name] = ri.Config
	}
	repoFile := RepoFile{
		Repos: repos,
	}
	yamlOut, err := yaml.Marshal(&repoFile)
	if err != nil {
		panic(err)
	}
	ioutil.WriteFile(filename, yamlOut, 0644)
}

func generateConfig(filename string) {
	repoFile := RepoFile{
		Repos: map[string]repoConfig{
			"MyRepo": {},
			"MyOtherRepo": {},
		},
		Config: config {
			Color: true,
			Defaults: repoConfig {
				Fetch: true,
			},
		},
	}
	yamlOut, err := yaml.Marshal(&repoFile)
	if err != nil {
		panic(err)
	}
	ioutil.WriteFile(filename, yamlOut, 0644)
}

func (r repoConfig) getTimeSinceLastCommit() time.Time {
	cmd := r.gitCommand("log", "--pretty=format:%at", "-1")
	out, err := cmd.Output()
	if err != nil {
		panic(err)
	}
	var timestamp int64
	fmt.Sscanf(string(out), "%d", &timestamp)
	return time.Unix(timestamp, 0)
}


func readDatabase(filename string) []*repoInfo {
	repoFile := RepoFile{}

	yml, err := ioutil.ReadFile(filename)
	if err != nil {
		panic(err)
	}
	yaml.Unmarshal(yml, &repoFile)

	database := make([]*repoInfo, 0, len(repoFile.Repos))
	for name, rp := range repoFile.Repos {
		rp.Name = name
		ri := repoInfo{
			Config: rp,
		}
		database = append(database, &ri)
	}
	return database
}

func (r repoConfig) getState() repoState {
	return repoState{
		Dirty:               r.hasUnstagedChanges(),
		UntrackedFiles:      r.hasUntrackedFiles(),
		TimeSinceLastCommit: r.getTimeSinceLastCommit(),
	}
}

func addRepoState(database []*repoInfo) {
	for _, ri := range database {
		ri.State = ri.Config.getState()
	}
}

func getDummyRepo() *repoInfo {

	ri := repoInfo{
		Config: repoConfig{
			Path:      "/my/repo/path/focustree",
			Name:      "focustree",
			ShortName: "ft",
		},
		State: repoState{
			Dirty:               true,
			UntrackedFiles:      false,
			TimeSinceLastCommit: time.Unix(0, 0),
		},
	}
	return &ri
}

func main() {

	args := getArgs()
	fmt.Println(args)
	if args.generateConfig {
		generateConfig("Rename_to_.repos.yml")
		fmt.Println("Generated config file 'Rename_to_.repos.yml'")
		return
	}

	database := readDatabase("repos.yml")

	addRepoState(database)

	fmt.Println("Repo                     Status              Date of last commit")
	for _, ri := range database {
		fmt.Printf("\033[;1m%-16s\033[0m", ri.Config.Name)

		if ri.State.Dirty {
			fmt.Printf(" \033[33mDirty\033[0m")
		} else {
			fmt.Printf(" \033[32mClean\033[0m")
		}

		if ri.State.UntrackedFiles {
			fmt.Printf(" \033[33mUntracked Files   \033[0m")
		} else {
			fmt.Printf(" \033[32mNo untracked files\033[0m")
		}
		dt := time.Now().Sub(ri.State.TimeSinceLastCommit)
		fmt.Printf("       %-4d Hours\n", int(dt.Hours()))
	}
}
