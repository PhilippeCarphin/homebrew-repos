package main

import (
	"flag"
	"fmt"
	"strings"
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
	RemoteState         RemoteState
	StagedChanges       bool
}

type repos []repoConfig

func (r repoConfig) gitCommand(args ...string) *exec.Cmd {
	time.Sleep(time.Millisecond * 500)
	cmd := exec.Command("git", args...)
	cmd.Stderr = os.Stderr
	cmd.Dir = r.Path
	return cmd
}

func (r *repoConfig) hasUnstagedChanges() (bool, error) {
	cmd := r.gitCommand("diff", "--no-ext-diff", "--quiet", "--exit-code")
	_ = cmd.Run()
	if cmd.ProcessState == nil {
		return false, fmt.Errorf("Failed to run command %v for repo %v", cmd, r)
	}
	return !cmd.ProcessState.Success(), nil
}

func (r *repoConfig) hasStagedChanges() (bool, error) {
	cmd := r.gitCommand("diff", "--staged", "--no-ext-diff", "--quiet", "--exit-code")
	_ = cmd.Run()
	if cmd.ProcessState == nil {
		return false, fmt.Errorf("Failed to run command %v for repo %v", cmd, r)
	}
	return !cmd.ProcessState.Success(), nil
}

type RemoteState int

const (
	RemoteStateNormal = iota
	RemoteStateDiverged
	RemoteStateBehind
	RemoteStateAhead
	RemoteStateUnknown
)

func (r *repoConfig) getRemoteState() (RemoteState, error) {
	cmd := r.gitCommand("status")
	out, err := cmd.Output()
	if err != nil {
		return RemoteStateNormal, fmt.Errorf("could not run git command for repo %s", r.Path)
	}

	sout := string(out)
	if strings.Contains(sout, "Your branch is behind") {
		return RemoteStateBehind, nil
	}

	if strings.Contains(sout, "Your branch is ahead") {
		return RemoteStateAhead, nil
	}

	if strings.Contains(sout, "different commits each, respectively") {
		return RemoteStateDiverged, nil
	}

	return RemoteStateNormal, nil
}

func (r *repoConfig) hasUntrackedFiles() (bool, error) {
	cmd := r.gitCommand("ls-files", r.Path, "--others", "--exclude-standard")
	out, err := cmd.Output()
	if err != nil {
		return false, fmt.Errorf("Could not run git command for repo '%s' : %v", r.Path, err)
	}
	return len(out) != 0, nil
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
	y := `repos:
  RepoName:
    path: "/path/to/git/repo"
  MyOtherRepoName:
    path: "/path/to/other/git/repo"
config:
  color: true
  defaults:
    # Default values for repos
    path: ""
    name: ""
    shortname: ""
    fetch: true
    comment: ""
`
	ioutil.WriteFile(filename, []byte(y), 0644)
}

func (r repoConfig) getTimeSinceLastCommit() (time.Time, error) {
	cmd := r.gitCommand("log", "--pretty=format:%at", "-1")
	out, err := cmd.Output()
	if err != nil {
		return time.Unix(0, 0), fmt.Errorf("Could not get time since last commit for repo '%s' : %v", r.Path, err)
	}
	var timestamp int64
	fmt.Sscanf(string(out), "%d", &timestamp)
	return time.Unix(timestamp, 0), nil
}

func readDatabase(filename string) ([]*repoInfo, error) {
	repoFile := RepoFile{}

	yml, err := ioutil.ReadFile(filename)
	if err != nil {
		return nil, err
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
	return database, nil
}

func (r repoConfig) getState() (repoState, error) {

	state := repoState{}
	var err error

	cmd := r.gitCommand("fetch")
	cmd.Stderr = nil
	_ = cmd.Run()
	if cmd.ProcessState == nil {
		return state, fmt.Errorf("error encountered when attempting to fetch '%s'", r.Path)
	}
	if cmd.ProcessState.Success() {
		state.RemoteState, err = r.getRemoteState()
		if err != nil {
			return state, err
		}
	} else {
		state.RemoteState = RemoteStateUnknown
	}



	state.Dirty, err = r.hasUnstagedChanges()
	if err != nil {
		return state, err
	}

	state.UntrackedFiles, err = r.hasUntrackedFiles()
	if err != nil {
		return state, err
	}

	state.TimeSinceLastCommit, err = r.getTimeSinceLastCommit()
	if err != nil {
		return state, err
	}

	state.StagedChanges, err = r.hasStagedChanges()
	if err != nil {
		return state, err
	}

	return state, nil
}

func addRepoState(database []*repoInfo) {
	var wg sync.WaitGroup
	for _, ri := range database {
		wg.Add(1)
		go func(r *repoInfo) {
			defer wg.Done()
			var err error
			r.State, err = r.Config.getState()
			if err != nil {
				panic(err)
			}
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
	if args.generateConfig {
		generateConfig("Rename_to_.repos.yml")
		fmt.Println("Generated config file 'Rename_to_.repos.yml'")
		return
	}

	home, err := os.UserHomeDir()
	if err != nil {
		panic(err)
	}
	database, err := readDatabase(filepath.Join(home, ".repos.yml"))
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	infoCh := make(chan *repoInfo, 100)
	var wg sync.WaitGroup
	for _, ri := range database {
		wg.Add(1)
		go func(r *repoInfo) {
			var err error
			r.State, err = r.Config.getState()
			if err != nil {
				fmt.Println(err)
				infoCh <- nil
				return
			}
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

func (rs RemoteState) String() string {
	switch rs {
	case RemoteStateNormal:
		return "normal"
	case RemoteStateBehind:
		return "behind"
	case RemoteStateAhead:
		return "ahead"
	case RemoteStateDiverged:
		return "diverged"
	case RemoteStateUnknown:
		return "unknown"
	}
	return "UNKNOWN"
}

func printRepoInfo(ri *repoInfo) {

	fmt.Printf("\033[;1m%-28s\033[0m", ri.Config.Name)

	switch ri.State.RemoteState {
	case RemoteStateNormal:
		fmt.Printf("%8s ", "")
	case RemoteStateBehind, RemoteStateAhead, RemoteStateDiverged:
		fmt.Printf("\033[1;35m%8v\033[0m ", ri.State.RemoteState)
	case RemoteStateUnknown:
		fmt.Printf("\033[1;37;41m%v\033[0m  ", ri.State.RemoteState)
	}

	if ri.State.StagedChanges && ri.State.Dirty {
		fmt.Printf(" \033[1;4;33m%-17s\033[0m ", "Staged & Unstaged")
	} else if ri.State.StagedChanges {
		fmt.Printf(" \033[1;33m%-17s\033[0m ", "Staged")
	} else if ri.State.Dirty {
		fmt.Printf(" \033[33m%-17s\033[0m ", "Unstaged")
	} else {
		fmt.Printf(" \033[32m%-17s\033[0m ", "Clean")
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
