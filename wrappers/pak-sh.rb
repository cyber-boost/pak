# Homebrew formula for PAK.sh Wrapper
# https://pak.sh

class PakSh < Formula
  desc "PAK.sh - Universal Package Automation Kit Wrapper"
  homepage "https://pak.sh"
  url "https://github.com/cyber-boost/pak/archive/v2.0.1.tar.gz"
  sha256 "SKIP"  # Will be calculated during release
  license "MIT"
  head "https://github.com/cyber-boost/pak.git", branch: "main"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  depends_on "bash" => :build
  depends_on "curl" => :build

  def install
    # Install the wrapper script
    bin.install "wrappers/pak-sh"
    
    # Make it executable
    chmod 0755, bin/"pak-sh"
    
    # Create symlink for 'pak' command
    bin.install_symlink "pak-sh" => "pak"
    
    # Install documentation
    man1.install "docs/man/pak-sh.1" if File.exist?("docs/man/pak-sh.1")
    
    # Install bash completion
    bash_completion.install "completions/bash/pak-sh" if File.exist?("completions/bash/pak-sh")
    
    # Install zsh completion
    zsh_completion.install "completions/zsh/_pak-sh" if File.exist?("completions/zsh/_pak-sh")
    
    # Install fish completion
    fish_completion.install "completions/fish/pak-sh.fish" if File.exist?("completions/fish/pak-sh.fish")
  end

  def post_install
    # Create configuration directory
    (etc/"pak-sh").mkpath
    
    # Set up default configuration
    unless (etc/"pak-sh/config.json").exist?
      (etc/"pak-sh/config.json").write <<~EOS
        {
          "version": "2.0.0",
          "install_dir": "#{opt_prefix}/bin",
          "config_dir": "#{etc}/pak-sh",
          "data_dir": "#{var}/lib/pak-sh",
          "log_dir": "#{var}/log/pak-sh"
        }
      EOS
    end
  end

  def caveats
    <<~EOS
      🚀 PAK.sh Wrapper has been installed!
      
      To install PAK.sh, run:
        pak-sh install
      
      To check status:
        pak-sh status
      
      To run PAK.sh commands:
        pak-sh run init
        pak-sh run deploy my-package
        pak-sh run web
      
      Documentation: https://pak.sh/docs
      GitHub: https://github.com/cyber-boost/pak
    EOS
  end

  test do
    # Test that the wrapper script exists and is executable
    assert_predicate bin/"pak-sh", :exist?
    assert_predicate bin/"pak-sh", :executable?
    
    # Test that the symlink exists
    assert_predicate bin/"pak", :exist?
    
    # Test help command
    output = shell_output("#{bin}/pak-sh --help", 0)
    assert_match "PAK.sh Wrapper Script", output
    
    # Test version command
    output = shell_output("#{bin}/pak-sh --version", 0)
    assert_match "2.0.0", output
  end
end 