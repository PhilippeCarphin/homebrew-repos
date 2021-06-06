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

	"io"
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
	njobs          int
	noFetch        bool
	repo           string
	listNames      bool
	getDir         string
	configFile     string
	recent         bool
	days           int
}


func getArgs() args {

	var a args

	a.command = flag.Arg(0)
	flag.StringVar(&a.path, "path", "", "Specify a single repo to give info for")
	flag.BoolVar(&a.generateConfig, "generate-config", false, "Look for git repos in PWD and generate ~/.config/repos.yml file content on STDOUT.")
	flag.IntVar(&a.njobs, "j", 1, "Number of concurrent repos to do")
	flag.BoolVar(&a.noFetch, "no-fetch", false, "Disable auto-fetching")
	flag.StringVar(&a.repo, "r", "", "Start new shell with cleared environment in repo")
	flag.BoolVar(&a.listNames, "list-names", false, "Output list of names on a single line for autocomplete")
	flag.StringVar(&a.getDir, "get-dir", "", "Get directory of repo on STDOUT")
	flag.StringVar(&a.configFile, "F", "", "Use a different config file that ~/.config/repos.yml")
	flag.BoolVar(&a.recent, "recent", false, "Show today and yesterday's commits for all repos")
	flag.IntVar(&a.days, "days", 1, "Go back more than one day before yesterday when using option -recent")
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
	// time.Sleep(time.Millisecond * 500)
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

func showRecentCommits(database []*repoInfo, args args) error {
	for _, ri := range database {
		cmd := ri.Config.gitCommand("recent", "-d", fmt.Sprintf("%d", (args.days)))
		out, err := cmd.Output()
		if err != nil {
			fmt.Printf("Could not get recent commits for %s: %v\n", ri.Config.Path, err)
		}
		fmt.Print(string(out))
	}
	return nil
}

func generateConfig(filename string) {

	y := strings.Builder{}
	nbRepos := 0

	subdirs, err := ioutil.ReadDir(".")
	if err != nil {
		panic(err)
	}

	fmt.Fprintf(&y, "repos:\n")
	for _, f := range subdirs {
		gitdir := fmt.Sprintf("%s/.git", f.Name())
		if _, err := os.Stat(gitdir); err != nil {
			continue
		}
		nbRepos++
		repoName := f.Name()
		repoPath := fmt.Sprintf("%s/%s", os.Getenv("PWD"), f.Name())
		fmt.Fprintf(&y, "  %s:\n    path: \"%s\"\n", repoName, repoPath)
	}

	if nbRepos == 0 {
		fmt.Fprintf(os.Stderr, "No git repos found in %s\n", os.Getenv("PWD"))
	}

	if filename != "" {
		ioutil.WriteFile(filename, []byte(y.String()), 0644)
	} else {
		fmt.Printf(y.String())
	}
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

func (r repoConfig) fetch() error {
	cmd := r.gitCommand("fetch")
	cmd.Stderr = nil
	_ = cmd.Run()
	if cmd.ProcessState == nil {
		return fmt.Errorf("error encountered when attempting to fetch '%s'", r.Path)
	}
	if ! cmd.ProcessState.Success() {
		return fmt.Errorf("fetch command failed for repo '%s' : %v", r.Path, cmd.ProcessState.ExitCode())
	}
	return nil
}

func (r repoConfig) getState(fetch bool) (repoState, error) {

	state := repoState{}
	var err error

	if fetch {
		err := r.fetch()
		if err != nil {
			state.RemoteState = RemoteStateUnknown
			return state, err
		}
	}

	remoteState, err := r.getRemoteState()
	if err != nil {
		return state, err
	}
	state.RemoteState = remoteState

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
func newShellInDir(directory string) (int, error) {

	fmt.Fprintf(os.Stderr, "\033[33mWARNING: This is a beta feature, maybe use rcd instead\033[0m\n")
	err := os.Chdir(directory)
	if err != nil {
		return 1, fmt.Errorf("could not cd to '%s', : %v", directory, err)
	}
	cmd := exec.Command("/bin/bash", "-l")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin
	fmt.Printf("\033[1;37m==> \033[0mStarting new shell in \033[1;32m%s\033[0m\n", directory)
	baseEnv := []string{
		"DISPLAY=" + os.Getenv("DISPLAY"),
		"HOME=" + os.Getenv("HOME"),
		"LANG=" + os.Getenv("LANG"),
		"LC_TERMINAL=" + os.Getenv("LC_TERMINAL"),
		"LC_TERMINAL_VERSION=" + os.Getenv("LC_TERMINAL_VERSION"),
		"LOGNAME=" + os.Getenv("LOGNAME"),
		"MAIL=" + os.Getenv("MAIL"),
		"SHELL=" + os.Getenv("SHELL"),
		"SSH_CLIENT=" + os.Getenv("SSH_CLIENT"),
		"SSH_CONNECTION=" + os.Getenv("SSH_CONNECTION"),
		"TERM=" + os.Getenv("TERM"),
		"TMUX=" + os.Getenv("TMUX"),
		"USER=" + os.Getenv("USER"),
	}
	cmd.Env = append(baseEnv, "REPOS_CONTEXT="+directory)
	err = cmd.Run()
	fmt.Printf("\033[1;37m==> \033[0mBack from new shell in \033[1;32m%s\033[0m\n", directory)
	return cmd.ProcessState.ExitCode(), nil
}

func newShellInRepo(database []*repoInfo, repoName string) (int, error) {
	for _, ri := range database {
		if ri.Config.Name == repoName {
			return newShellInDir(ri.Config.Path)
		}
	}
	return 1, fmt.Errorf("could not find repo '%s' in ~/.config/repos.yml", repoName)
}
func generateShellAutocomplete(database []*repoInfo, args args, out io.Writer) error {

	for _, ri := range database {
		fmt.Fprintf(os.Stdout, "complete -f -c repos -n 'contains -- -r (commandline -opc)' -a %s -d %s\n", ri.Config.Name, ri.Config.Path)
	}

	return nil
}

func getRepoDir(database []*repoInfo, repoName string) (string, error) {
	for _, ri := range database {
		if ri.Config.Name == repoName {

			return ri.Config.Path, nil
		}
	}
	return "", fmt.Errorf("no repo with name '%s' in database", repoName)
}

func main() {

	args := getArgs()
	if args.generateConfig {
		generateConfig("")
		return
	}

	if args.path != "" {
		ri := repoInfo{}
		ri.Config.Name = fmt.Sprintf("-path %s", args.path)
		ri.Config.Path = args.path
		var err error
		ri.State, err = ri.Config.getState(!args.noFetch)
		if err != nil {
			panic(err)
		}
		printRepoInfo(&ri)
		return
	}

	home, err := os.UserHomeDir()
	if err != nil {
		panic(err)
	}

	var databaseFile string
	if args.configFile != "" {
		databaseFile = args.configFile
	} else {
		databaseFile = filepath.Join(home, ".config", "repos.yml")
	}

	database, err := readDatabase(databaseFile)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	if args.recent {
		showRecentCommits(database, args)
		return
	}

	if len(database) == 0 {
		fmt.Printf("\033[33mWARNING\033[0m No repos listed in $HOME/.config/repos.yml\n")
	}

	if args.listNames {
		for _, ri := range database {
			fmt.Printf("%s\n", ri.Config.Name)
		}
		return
	}

	if args.repo != "" {
		exitCode, err := newShellInRepo(database, args.repo)
		if err != nil {
			panic(err)
		}
		os.Exit(exitCode)
	}
	if args.getDir != "" {
		repoDir, err := getRepoDir(database, args.getDir)
		if err != nil {
			panic(err)
		}
		fmt.Println(repoDir)
		return
	}

	sem := make(chan struct{}, args.njobs)
	infoCh := make(chan *repoInfo)
	var wg sync.WaitGroup
	for _, ri := range database {
		wg.Add(1)
		go func(r *repoInfo) {
			sem <- struct{}{}
			defer func() { <-sem }()
			var err error
			r.State, err = r.Config.getState(!args.noFetch)
			if err != nil {
				fmt.Println(err)
				r.State.RemoteState = RemoteStateUnknown
			}
			infoCh <- r
		}(ri)
	}
	printRepoInfoHeader()
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

func printRepoInfoHeader(){
	fmt.Printf("REPO                       REMOTE STATE                 STATUS                    TSLC     COMMENT\n")
}
func printRepoInfo(ri *repoInfo) {

	fmt.Printf("\033[;1m%-28s\033[0m", ri.Config.Name)

	switch ri.State.RemoteState {
	case RemoteStateNormal:
		fmt.Printf("%11s ", "Up to Date")
	case RemoteStateBehind, RemoteStateAhead, RemoteStateDiverged:
		fmt.Printf("\033[1;35m%11v\033[0m ", ri.State.RemoteState)
	case RemoteStateUnknown:
		fmt.Printf("\033[1;37;41m%11v\033[0m  ", ri.State.RemoteState)
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
