{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    histSize = 50000;
    histFile = "$HOME/.zsh_history";
    setOptions = [
      "EXTENDED_HISTORY"
      "HIST_EXPIRE_DUPS_FIRST"
      "HIST_IGNORE_DUPS"
      "HIST_IGNORE_SPACE"
      "HIST_VERIFY"
      "SHARE_HISTORY"
    ];

    promptInit = ''
      export VIRTUAL_ENV_DISABLE_PROMPT=1

      function virtualenv_info {
        [ -n "$VIRTUAL_ENV" ] && echo '('%F{blue}`basename "$VIRTUAL_ENV"`%f') '
      }
      PR_GIT_UPDATE=1

      setopt prompt_subst
      autoload -U add-zsh-hook
      autoload -Uz vcs_info

      if [[ $terminfo[colors] -ge 256 ]]; then
        turquoise="%F{81}"
        orange="%F{166}"
        purple="%F{135}"
        hotpink="%F{161}"
        limegreen="%F{118}"
      else
        turquoise="%F{cyan}"
        orange="%F{yellow}"
        purple="%F{magenta}"
        hotpink="%F{red}"
        limegreen="%F{green}"
      fi

      zstyle ':vcs_info:*' enable git svn
      zstyle ':vcs_info:*:prompt:*' check-for-changes true

      PR_RST="%f"
      FMT_BRANCH="(%{$turquoise%}%b%u%c''${PR_RST})"
      FMT_ACTION="(%{$limegreen%}%a''${PR_RST})"
      FMT_UNSTAGED="%{$orange%}●"
      FMT_STAGED="%{$limegreen%}●"

      zstyle ':vcs_info:*:prompt:*' unstagedstr   "''${FMT_UNSTAGED}"
      zstyle ':vcs_info:*:prompt:*' stagedstr     "''${FMT_STAGED}"
      zstyle ':vcs_info:*:prompt:*' actionformats "''${FMT_BRANCH}''${FMT_ACTION}"
      zstyle ':vcs_info:*:prompt:*' formats       "''${FMT_BRANCH}"
      zstyle ':vcs_info:*:prompt:*' nvcsformats   ""

      function steeef_preexec {
        case "$2" in
          *git*|*hub*|*svn*) PR_GIT_UPDATE=1 ;;
        esac
      }
      add-zsh-hook preexec steeef_preexec

      function steeef_chpwd {
        PR_GIT_UPDATE=1
      }
      add-zsh-hook chpwd steeef_chpwd

      function steeef_precmd {
        if [[ -n "$PR_GIT_UPDATE" ]] ; then
          if git ls-files --other --exclude-standard 2> /dev/null | grep -q "."; then
            FMT_BRANCH="(%{$turquoise%}%b%u%c%{$hotpink%}●''${PR_RST})"
          else
            FMT_BRANCH="(%{$turquoise%}%b%u%c''${PR_RST})"
          fi
          zstyle ':vcs_info:*:prompt:*' formats "''${FMT_BRANCH} "
          vcs_info 'prompt'
          PR_GIT_UPDATE=
        fi
      }
      add-zsh-hook precmd steeef_precmd

      PROMPT=$'
%{$purple%}%n''${PR_RST} at %{$orange%}%m''${PR_RST} in %{$limegreen%}%~''${PR_RST} $vcs_info_msg_0_$(virtualenv_info)
$ '
    '';

    interactiveShellInit = ''
      setopt no_nomatch
      setopt interactivecomments

      bindkey "\e[1~" beginning-of-line
      bindkey "\e[4~" end-of-line
      bindkey "^[[5~" up-line-or-history
      bindkey "^[[6~" down-line-or-history
      bindkey "\e[3~" delete-char
      bindkey "\e[2~" quoted-insert
      bindkey "\e[5C" forward-word
      bindkey "\eOc" emacs-forward-word
      bindkey "\e[5D" backward-word
      bindkey "\eOd" emacs-backward-word
      bindkey "\ee[C" forward-word
      bindkey "\ee[D" backward-word
      bindkey "\e[8~" end-of-line
      bindkey "\e[7~" beginning-of-line
      bindkey "\eOH" beginning-of-line
      bindkey "\eOF" end-of-line
      bindkey "\e[H" beginning-of-line
      bindkey "\e[F" end-of-line
      bindkey '^i' expand-or-complete-prefix

      bindkey -s "^[Op" "0"
      bindkey -s "^[On" "."
      bindkey -s "^[OM" "^M"
      bindkey -s "^[Oq" "1"
      bindkey -s "^[Or" "2"
      bindkey -s "^[Os" "3"
      bindkey -s "^[Ot" "4"
      bindkey -s "^[Ou" "5"
      bindkey -s "^[Ov" "6"
      bindkey -s "^[Ow" "7"
      bindkey -s "^[Ox" "8"
      bindkey -s "^[Oy" "9"
      bindkey -s "^[Ol" "+"
      bindkey -s "^[Om" "-"
      bindkey -s "^[Oj" "*"
      bindkey -s "^[Oo" "/"
    '';
  };

  users.defaultUserShell = pkgs.zsh;
}
