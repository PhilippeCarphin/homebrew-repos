package main

import (
	"fmt"

	"os"
	"os/exec"

	"io/ioutil"

	"gopkg.in/yaml.v2"
)

type config struct {
	color    bool
	defaults repoConfig
}

type repoConfig struct {
	Path      string
	Name      string
	ShortName string
}

type repoInfo struct {
	Config repoConfig
	State  repoState
}

type repoState struct {
	Dirty          bool
	UntrackedFiles bool
	// TODO Transform to proper date time type
	TimeSinceLastCommit string
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
	cmd.Run()
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
		},
	}
	yamlOut, err := yaml.Marshal(&repoFile)
	if err != nil {
		panic(err)
	}
	ioutil.WriteFile(filename, yamlOut, 0644)
}

func (r repoConfig) getTimeSinceLastCommit() string {
	cmd := r.gitCommand("log", "--pretty=format:'%at'", "-1")
	out, err := cmd.Output()
	if err != nil {
		panic(err)
	}
	var timestamp int
	fmt.Sscanf(string(out), "%d", &timestamp)
	return string(out)
}

// RepoFile sucks
type RepoFile struct {
	Repos map[string]repoConfig
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

func addRepoState(database []*repoInfo) {
	for _, ri := range database {
		ri.State = repoState{
			Dirty:               ri.Config.hasUnstagedChanges(),
			UntrackedFiles:      ri.Config.hasUntrackedFiles(),
			TimeSinceLastCommit: ri.Config.getTimeSinceLastCommit(),
		}
	}
}

func main() {

	database := readDatabase("repos.yml")

	addRepoState(database)

	for _, ri := range database {
		fmt.Println(ri.State)
	}

	ri := repoInfo{
		Config: repoConfig{
			Path:      "/my/repo/path/focustree",
			Name:      "focustree",
			ShortName: "ft",
		},
		State: repoState{
			Dirty:               true,
			UntrackedFiles:      false,
			TimeSinceLastCommit: "",
		},
	}
	database = append(database, &ri)

}
