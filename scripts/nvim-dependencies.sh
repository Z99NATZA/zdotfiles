# Read-only dependency helpers. Package installation is a separate manual step.
nvim_dependency_paths() {
    nvim_tools_root="${XDG_DATA_HOME:-$HOME/.local/share}/zdotfiles"
    export PATH="$nvim_tools_root/bin:$PATH"
}

nvim_version_supported() {
    local version
    command -v nvim >/dev/null 2>&1 || return 1
    version=$(NVIM_LOG_FILE=/dev/null nvim --version) || return 1
    [[ $version =~ NVIM\ v([0-9]+)\.([0-9]+)\.([0-9]+) ]] || return 1
    (( BASH_REMATCH[1] > 0 || BASH_REMATCH[2] > 11 || (BASH_REMATCH[2] == 11 && BASH_REMATCH[3] >= 2) ))
}
