# music-index-tools

Build and query a music similarity index from MERT embeddings:

- `music-index` — scan a music library, embed every track through `music-embed`, and keep an
  incremental on-disk index.
- `music-similar` — print the nearest neighbours of a track (or of the current MPRIS track).

This is the Rust port of the `music_index.py` / `music_similar.py` payloads from the
`nixos-config` repository. The CLI, cache keys, index layout and the `--selftest` modes are
unchanged, and the on-disk format stays numpy-compatible.

## Design

The ML embedding stays in Python: `music-index` shells out to a `music-embed` executable for
every batch of embeddings instead of importing torch. This crate owns the scan, the cache, the
index signature/migration logic, the `.npy` reader/writer and the ranking.

The `.npy` implementation is in-crate (float32, C order, little-endian, v1/v2 headers), so there
is no numpy dependency anywhere on this side.

## Nix

```bash
nix build .#default            # this repository's package
nix build .#checks.x86_64-linux.selftest
nix develop                    # cargo, rustc, clippy, rustfmt, rust-analyzer
nix flake check
```

The host configuration consumes this flake as an input and maps
`packages.<system>.default` onto `pkgs.neg.music-index-tools`; the input follows the host's
`nixpkgs`, so the binary is built against the system pin rather than against a second snapshot.

## Usage

```bash
# Build (or refresh incrementally) the index for a library, default ~/music.
music-index ~/music

# Report scanned files that never made it into the index.
music-index --audit

# Nearest neighbours, default 15, current MPRIS track when no path is given.
music-similar
music-similar ~/music/Artist/Album/Track.flac -k 10

# Recentre away from the corpus mean, machine-readable output.
music-similar --no-center --json
```

`music-index --help` and `music-similar --help` carry the full flag list.

Embedding settings are part of the index signature: changing `--model`, `--layer`,
`--window-seconds` or `--windows` re-embeds the whole library. The index lives in
`~/.cache/music-index` (`vectors.npy`, `tracks.jsonl`, `meta.json`, `cache/`, `center.npy`).

## Environment

| Variable | Used by | Default |
| --- | --- | --- |
| `MUSIC_EMBED_BIN` | `music-index` | `music-embed` on `PATH` |
| `MUSIC_EMBED_MODEL` | `music-index` | `m-a-p/MERT-v1-95M` |
| `MUSIC_DIR` | `music-similar --queue` | `~/music` |
| `MPC_CMD` | `music-similar --queue` | `mpc` |

## Self-checks

Both binaries ship a deterministic SHAKE-128 stub embedder, so the whole pipeline can be
exercised without torch, a model or a music library:

```bash
music-index --selftest
music-similar --selftest
```

The flake check `selftest` runs both.

## License

MIT, see `LICENSE`.
