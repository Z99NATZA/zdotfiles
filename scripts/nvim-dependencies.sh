# Sourced by zdotfiles; only setup may install dependencies.
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

nvim_dependency_platform() {
    [[ -r /etc/os-release ]] || return 1
    local ID VERSION_ID
    . /etc/os-release
    [[ $ID = ubuntu && $VERSION_ID = 26.04 ]]
}

nvim_setup_dependencies() {
    local executable package rustup_path
    local need_rust=false need_python=false
    local -a packages=() privilege=()
    nvim_version_supported || packages+=(neovim)
    while read -r executable package; do
        command -v "$executable" >/dev/null 2>&1 || packages+=("$package")
    done <<'PACKAGES'
git git
cc build-essential
curl curl
tar tar
rg ripgrep
PACKAGES
    if ! command -v rust-analyzer >/dev/null 2>&1 || ! rust-analyzer --version >/dev/null 2>&1; then
        need_rust=true
        command -v rustup >/dev/null 2>&1 || packages+=(rustup)
    fi
    if ! command -v basedpyright-langserver >/dev/null 2>&1; then
        need_python=true
        if ! command -v python3 >/dev/null 2>&1 || ! python3 -c 'import venv, ensurepip' >/dev/null 2>&1; then
            packages+=(python3-venv)
        fi
    fi
    if [[ -n ${WAYLAND_DISPLAY:-} ]]; then
        if ! command -v wl-copy >/dev/null 2>&1 || ! command -v wl-paste >/dev/null 2>&1; then
            packages+=(wl-clipboard)
        fi
    elif [[ -n ${DISPLAY:-} ]]; then
        if ! command -v xclip >/dev/null 2>&1 && ! command -v xsel >/dev/null 2>&1; then
            packages+=(xclip)
        fi
    fi
    if ((${#packages[@]} == 0)) && ! $need_rust && ! $need_python; then
        return
    fi
    nvim_dependency_platform || die 'automatic Neovim dependencies require Ubuntu 26.04; install prerequisites manually on other systems'
    if $dry_run; then
        ((${#packages[@]} == 0)) || note "would install Ubuntu packages: ${packages[*]} (apt-get update/install; sudo when needed)"
        ! $need_rust || note 'would install stable Rust with rust-analyzer and a managed launcher'
        ! $need_python || note 'would install basedpyright 1.40.2 in a managed Python virtual environment'
        return
    fi
    if ((${#packages[@]})); then
        if (( EUID != 0 )); then
            command -v sudo >/dev/null 2>&1 || die 'sudo is required to install Ubuntu packages'
            privilege=(sudo)
        fi
        note "installing Ubuntu packages: ${packages[*]}"
        "${privilege[@]}" apt-get update || die 'apt-get update failed; configuration was not deployed'
        "${privilege[@]}" apt-get install -y "${packages[@]}" || die 'apt-get install failed; configuration was not deployed'
        hash -r
    fi
    if $need_rust; then
        rustup toolchain install stable --profile minimal --no-self-update --component rust-analyzer || die 'Rust toolchain installation failed'
        rustup_path=$(command -v rustup)
        mkdir -p "$nvim_tools_root/bin"
        # Select stable explicitly without changing the user's default toolchain.
        printf '#!/usr/bin/env bash\nexec %q run stable rust-analyzer "$@"\n' "$rustup_path" > "$nvim_tools_root/bin/rust-analyzer"
        chmod +x "$nvim_tools_root/bin/rust-analyzer"
    fi
    if $need_python; then
        python3 -m venv "$nvim_tools_root/venvs/basedpyright" || die 'Python virtual environment creation failed'
        "$nvim_tools_root/venvs/basedpyright/bin/python" -m pip install basedpyright==1.40.2 || die 'Basedpyright installation failed'
        mkdir -p "$nvim_tools_root/bin"
        ln -sfn "$nvim_tools_root/venvs/basedpyright/bin/basedpyright-langserver" "$nvim_tools_root/bin/basedpyright-langserver"
    fi
}
