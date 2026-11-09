# libdovi-android-builder

Builds [libdovi](https://github.com/quietvoid/dovi_tool/tree/main/dolby_vision),
the C API of dovi_tool's `dolby_vision` crate (MIT), as a static library for the
four Android ABIs. Output goes to `native/prebuilt/libdovi`:

```
include/libdovi/rpu_parser.h
lib/<abi>/libdovi.a
LICENSE
```

Requirements: Rust 1.88 or later (libdovi 3.4.0 uses edition 2024), rustup
(adds the Android targets) and cargo-c (`cargo install cargo-c`). The NDK is
located by `AVP/android-setup-light.sh`. Dependencies are pinned by upstream's
`Cargo.lock` (`--locked`).

Build from the workspace root:

```bash
make native_build_native/libdovi-android-builder
```

An ABI is skipped when its library and header are already installed; run
`make clean_prebuilt` to force a rebuild.
