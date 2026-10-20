# Versioning

## Releases

```text
Source of truth
==========
VERSION identifies the source configuration.
Setup installs the checked-out commit/tag.
Keep history in Git tags, not copied v1/v2/v3 directories.
```

```bash
# ---------- bash ---------- #

# Update the current branch and installation
git pull --ff-only
./zdotfiles setup
./zdotfiles verify

# After updating VERSION and committing the release
git tag v1.0.0
git push origin v1.0.0
```

## Historical Version

```bash
# ---------- bash ---------- #

# Clone and install a release
git clone --branch v1.0.0 git@github.com:Z99NATZA/zdotfiles.git
cd zdotfiles
./zdotfiles setup --dry-run
./zdotfiles setup
./zdotfiles verify
```
