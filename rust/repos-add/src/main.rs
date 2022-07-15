use serde_yaml;
use std::path::PathBuf;
use serde::{Deserialize, Serialize};
use dirs;
use std::fs::File;
// type RepoFile struct {
// 	Repos  map[string]repoConfig
// 	Config config
// }
use std::collections::HashMap;

#[derive(Debug, Serialize, Deserialize)]
struct RepoFile {
    repos: HashMap<String, RepoConfig>,
    config: Option<Config>,
}
// type config struct {
// 	Color    bool
// 	Defaults repoConfig
// }
#[derive(Debug, Serialize, Deserialize)]
struct Config {
    color: bool,
    defaults: RepoConfig,
}
//
// type repoConfig struct {
// 	Path      string
// 	Name      string
// 	ShortName string
// 	Fetch     bool
// 	Comment   string
// 	Remote    string
// }
#[derive(Debug, Serialize, Deserialize)]
struct RepoConfig {
    path:      String,
    #[serde(skip_serializing_if = "Option::is_none")]
    name:      Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    short_name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    fetch:     Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    comment:   Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    remote:    Option<String>,
}

//
// type repoInfo struct {
// 	Config repoConfig
// 	State  repoState
// }
//
// type repoState struct {
// 	Dirty               bool
// 	UntrackedFiles      bool
// 	TimeSinceLastCommit time.Time
// 	RemoteState         RemoteState
// 	StagedChanges       bool
// }
//
fn get_repo_file() -> Result<PathBuf,&'static str> {
    if let Some(mut path) = dirs::home_dir() {
        path.push(".config");
        path.push("repos");
        path.set_extension("yml");
        Ok(path)
    } else {
        Err("Could not get home dir")
    }
}

fn get_repo_data() -> Result<RepoFile, &'static str> {
    let filepath = get_repo_file()?;
    let file = File::open(filepath.clone());
    if let Ok(file) = file {
        let repo_file: Result<RepoFile,_> = serde_yaml::from_reader(file);
        if let Ok(repo_file) = repo_file {
            Ok(repo_file)
        } else {
            Err("Could not extract RepoFile struct from file contents")
        }
    } else {
        Err("Error opening file")
    }
}

fn main() {
    if let Ok(mut repo_data) = get_repo_data() {
        let new = RepoConfig{path:"path/to/my_repo".to_string(), name: None, fetch: None, remote: None, comment: None, short_name:None};
        repo_data.repos.insert("my_repo".to_string(), new);

        /*
         * Write modified repo_data to a different file for testing
         */
        if let Some(mut path) = dirs::home_dir() {
            path.push(".config");
            path.push("repos_rust_test");
            path.set_extension("yml");
            let c = File::create(&path);
            if let Ok(c) = c {
                if let Err(err) = serde_yaml::to_writer(c, &repo_data) {
                    println!("Error serializing to new file {:?}", err);
                }
            } else if let Err(err) = c {
                println!("Error creating file : {:?}", err);
            }
        } else {
            println!("Could not get home dir");
        }
    }
}
