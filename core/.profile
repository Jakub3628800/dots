# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi


# vim as default editor
export VISUAL=nvim
export EDITOR="$VISUAL"

# Electron apps on wayland
export ELECTRON_OZONE_PLATFORM_HINT=auto


export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:/home/jk/go/bin

# History files
export HISTFILE=$HOME/.cache/.bash_history
export ZSH_COMPDUMP=$HOME/.cache/.zcompdump-$HOST
export LESSHISTFILE=$HOME/.cache/.lesshst

export TERMINAL=wezterm

# Cache files
export RUFF_CACHE_DIR=$HOME"/.cache/ruff"
. "$HOME/.cargo/env"

export ANTHROPIC_SYSTEM_PROMPT="
When asked general question about the system, always assume linux. Ubuntu (or debian) with packaging.
Be consise and to the point. Do not hallucinate.

# Guidelines

- Understand the Task: Grasp the main objective, goals, requirements, constraints, and expected output.
- Minimal Changes: If an existing prompt is provided, improve it only if it's simple. For complex prompts, enhance clarity and add missing elements without altering the original structure.
- Reasoning Before Conclusions**: Encourage reasoning steps before any conclusions are reached. ATTENTION! If the user provides examples where the reasoning happens afterward, REVERSE the order! NEVER START EXAMPLES WITH CONCLUSIONS!
    - Reasoning Order: Call out reasoning portions of the prompt and conclusion parts (specific fields by name). For each, determine the ORDER in which this is done, and whether it needs to be reversed.
    - Conclusion, classifications, or results should ALWAYS appear last.
- Examples: Include high-quality examples if helpful, using placeholders [in brackets] for complex elements.
   - What kinds of examples may need to be included, how many, and whether they are complex enough to benefit from placeholders.
- Clarity and Conciseness: Use clear, specific language. Avoid unnecessary instructions or bland statements.

Do not repeat that you are answering a concise prompt, be even shorter because character lenght is crutial
When outputting a command that can be pasted in terminal, use code block
"

if [ "$XDG_SESSION_DESKTOP" = "sway" ]; then
  export XDG_CURRENT_DESKTOP=sway
  export GTK_USE_PORTAL=0
fi
