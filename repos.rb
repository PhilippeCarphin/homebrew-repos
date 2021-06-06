# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class Repos < Formula
  desc ""
  homepage ""
  url "https://gitlab.com/philippecarphin/repos.git"
  version "0.1.0"
  sha256 ""
  license ""

  depends_on "go" => :build

  def install
    # ENV.deparallelize  # if your formula fails when building in parallel
    # Remove unrecognized options if warned by configure
    # https://rubydoc.brew.sh/Formula.html#std_configure_args-instance_method
    system "make"
    bin.install "repos" => "repos"
    bin.install "scripts/git-recent" => "git-recent"
    man1.install "man/man1/repos.man" => "repos.1"
    man1.install "man/man1/rcd.man" => "rcd.1"
    share.install "completions" => "completions"
    # system "cmake", "-S", ".", "-B", "build", *std_cmake_args
  end

  def caveats
    s = <<~EOS
      Please source one of

        #{HOMEBREW_PREFIX}/share/completions/repos_completion.bash
        #{HOMEBREW_PREFIX}/share/completions/repos_completion.fish
        #{HOMEBREW_PREFIX}/share/completions/repos_completion.zsh

      in your ~/.bashrc, ~/.zshrc, or ~/.config/fish/config.fish.
    EOS
    s
  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! For Homebrew/homebrew-core
    # this will need to be a test that verifies the functionality of the
    # software. Run the test with `brew test repos`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    system "false"
  end
end
