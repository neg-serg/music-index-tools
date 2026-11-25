##
# Package: music-index-tools
# Purpose: Build and query the MERT music similarity index (`music-index`,
#   `music-similar`).
#
# The model itself stays Python: the indexer shells out to a `music-embed`
# executable (PATH, or `MUSIC_EMBED_BIN`) for every batch of embeddings. The
# `.npy` reader/writer is in-crate (float32, C order, little-endian, v1/v2
# headers), so there is no numpy dependency here.
#
# The `--selftest` modes both binaries ship use a deterministic SHAKE-128 stub
# embedder, so they need no torch, model or venv; the flake checks run them.
{
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "music-index-tools";
  version = (lib.importTOML ./Cargo.toml).package.version;

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  meta = {
    description = "Build and query the MERT music similarity index (music-index, music-similar)";
    homepage = "https://github.com/neg-serg/music-index-tools";
    license = lib.licenses.mit;
    mainProgram = "music-index";
    platforms = lib.platforms.unix;
  };
}
