package main

import (
	"flag"
	"fmt"
	"sync"
	"time"

	"os"
	"os/exec"
	"path/filepath"

	"io/ioutil"

	"gopkg.in/yaml.v2"
)

// RepoFile sucks
type RepoFile struct {
	Repos  map[string]repoConfig
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
	flag.StringVar(&a.path, "path", "", "Path of repo")
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
	Fetch     bool
	Comment   string
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
	time.Sleep(time.Millisecond * 500)
	cmd := exec.Command("git", args...)
	cmd.Stderr = os.Stderr
	cmd.Dir = r.Path
	return cmd
}

func (r *repoConfig) hasUnstagedChanges() bool {
	cmd := r.gitCommand("diff", "--no-ext-diff", "--quiet", "--exit-code")
	_ = cmd.Run()
	if cmd.ProcessState == nil {
		panic(fmt.Errorf("Failed to run command %v for repo %v",cmd, r))
	}
	return !cmd.ProcessState.Success()
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
			"MyRepo":      {},
			"MyOtherRepo": {},
		},
		Config: config{
			Color: true,
			Defaults: repoConfig{
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

	database := make([]*repoInfo, 0, len(repoFile.Repos)+8)
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
	usc := make(chan bool)
	utf := make(chan bool)
	tsl := make(chan time.Time)
	go func() { usc <- r.hasUnstagedChanges() }()
	go func() { utf <- r.hasUntrackedFiles() }()
	go func() { tsl <- r.getTimeSinceLastCommit() }()
	return repoState{
		Dirty:               <-usc,
		UntrackedFiles:      <-utf,
		TimeSinceLastCommit: <-tsl,
	}
}

func addRepoState(database []*repoInfo) {
	var wg sync.WaitGroup
	for _, ri := range database {
		wg.Add(1)
		go func(r *repoInfo) {
			defer wg.Done()
			r.State = r.Config.getState()
		}(ri)
	}
	wg.Wait()

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
	fmt.Printf("Args : %v\n", args)
	if args.generateConfig {
		generateConfig("Rename_to_.repos.yml")
		fmt.Println("Generated config file 'Rename_to_.repos.yml'")
		return
	}

	home, err := os.UserHomeDir()
	if err != nil {
		panic(err)
	}
	database := readDatabase(filepath.Join(home, ".repos.yml"))

	infoCh := make(chan *repoInfo)
	var wg sync.WaitGroup
	for _, ri := range database {
		wg.Add(1)
		go func(r *repoInfo) {
			r.State = r.Config.getState()
			infoCh <- r
		}(ri)
	}

	go func(wg *sync.WaitGroup) {
		for ri := range infoCh {
			printRepoInfo(ri)
			wg.Done()
		}
	}(&wg)

	wg.Wait()
}

func printRepoInfo(ri *repoInfo) {

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
	fmt.Printf(" %-4d Hours", int(dt.Hours()))
	fmt.Printf(" %s\n", ri.Config.Comment)
}
