# Versioning

`VERSION` identifies the current source configuration. Setup always installs
the version from the currently checked-out commit or tag.

Keep historical releases as Git tags instead of copying the source into `v1`,
`v2`, and `v3` directories.

## Update a Branch

From the repository directory:

```bash
git pull --ff-only
./zdotfiles setup
./zdotfiles verify
```

## Create a Release

Update `VERSION`, commit the release, and tag that commit:

```bash
# ---------- bash ---------- #

git tag v1.0.0
git push origin v1.0.0
```

## Install a Historical Version

```bash
# ---------- bash ---------- #

git clone --branch v1.0.0 git@github.com:Z99NATZA/zdotfiles.git
cd zdotfiles
./zdotfiles setup --dry-run
./zdotfiles setup
./zdotfiles verify
```
