{ pkgs, ... }:
{
  # -------------------------------------------------------------------
  # SSH Configuration for Multiple GitHub Accounts
  # -------------------------------------------------------------------
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "github.com-aahsnr-configs" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_rsa_aahsnr_configs";
        extraOptions = {
          AddKeysToAgent = "yes";
          IdentitiesOnly = "yes";
        };
      };
      "github.com-aahsnr-personal" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_rsa_aahsnr_personal";
        extraOptions = {
          AddKeysToAgent = "yes";
          IdentitiesOnly = "yes";
        };
      };
      "github.com-aahsnr-work" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_rsa_aahsnr_work";
        extraOptions = {
          AddKeysToAgent = "yes";
          IdentitiesOnly = "yes";
        };
      };
      "github.com-aahsnr-common" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_rsa_aahsnr_common";
        extraOptions = {
          AddKeysToAgent = "yes";
          IdentitiesOnly = "yes";
        };
      };
    };
  };

  # -------------------------------------------------------------------
  # Git Configuration
  # -------------------------------------------------------------------
  programs.git = {
    enable = true;
    package = pkgs.gitFull;

    userName = "aahsnr-configs";
    userEmail = "ahsanur041@proton.me";

    extraConfig = {
      init.defaultBranch = "main";
      "url \"git@github.com-aahsnr-configs:\"" = {
        insteadOf = "git@github.com:";
      };
    };

    includes = [
      {
        condition = "gitdir:~/git-repos/personal/";
        contents = {
          user = {
            name = "aahsnr-personal";
            email = "ahsanur041@gmail.com";
          };
          # When in this directory, rewrite github.com to use the personal key
          url = {
            "git@github.com-aahsnr-personal:" = {
              insteadOf = "git@github.com:";
            };
          };
        };
      }
      {
        condition = "gitdir:~/git-repos/work/";
        contents = {
          user = {
            name = "aahsnr-work";
            email = "aahsnr041@proton.me";
          };
          # When in this directory, rewrite github.com to use the work key
          url = {
            "git@github.com-aahsnr-work:" = {
              insteadOf = "git@github.com:";
            };
          };
        };
      }
      {
        condition = "gitdir:~/git-repos/common/";
        contents = {
          user = {
            name = "aahsnr-common";
            email = "ahsan.05rahman@gmail.com";
          };
          # When in this directory, rewrite github.com to use the common key
          url = {
            "git@github.com-aahsnr-common:" = {
              insteadOf = "git@github.com:";
            };
          };
        };
      }
    ];
  };

  # -------------------------------------------------------------------
  # GitHub CLI (gh) Configuration
  # -------------------------------------------------------------------
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      editor = "nvim";
      aliases = {
        "auth-configs" = "auth switch --hostname github.com --user aahsnr-configs";
        "auth-personal" = "auth switch --hostname github.com --user aahsnr-personal";
        "auth-work" = "auth switch --hostname github.com --user aahsnr-work";
        "auth-common" = "auth switch --hostname github.com --user aahsnr-common";
      };
    };
  };
}
