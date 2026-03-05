#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import pathlib
import shutil
import tempfile
import sys

ROOT = pathlib.Path.cwd()
sys.path.append(str(ROOT / "scripts" / "tests"))
from packs_runtime import PackRuntime  # noqa: E402

source_pack = ROOT / "packs" / "regart"
assert (source_pack / "manifest.yaml").exists()
assert (source_pack / "payload").exists()
assert (source_pack / "signatures" / "manifest.sha256").exists()

with tempfile.TemporaryDirectory() as td:
    base = pathlib.Path(td)

    pack_ok = base / "regart-ok"
    shutil.copytree(source_pack, pack_ok)
    rt = PackRuntime()
    ok = rt.install_pack_from_dir(pack_ok, catalog={"base-observability": ["1.0.0", "1.2.0"]})
    assert ok.ok and ok.activated and ok.gap_event is None

    pack_bad_sig = base / "regart-bad-signature"
    shutil.copytree(source_pack, pack_bad_sig)
    (pack_bad_sig / "signatures" / "manifest.sha256").write_text("0" * 64 + "  manifest.yaml\n", encoding="utf-8")
    bad_sig = rt.install_pack_from_dir(pack_bad_sig, catalog={"base-observability": ["1.0.0"]})
    assert not bad_sig.ok
    assert bad_sig.gap_event["kind"] == "observability_gap.pack_install_failed"
    assert bad_sig.gap_event["details"]["fail_stage"] == "signature"

    pack_missing_payload = base / "regart-missing-payload"
    shutil.copytree(source_pack, pack_missing_payload)
    shutil.rmtree(pack_missing_payload / "payload")
    bad_layout = rt.install_pack_from_dir(pack_missing_payload, catalog={"base-observability": ["1.0.0"]})
    assert not bad_layout.ok
    assert bad_layout.gap_event["details"]["fail_stage"] == "layout"

    pack_missing_dep = base / "regart-missing-dep"
    shutil.copytree(source_pack, pack_missing_dep)
    bad_deps = rt.install_pack_from_dir(pack_missing_dep, catalog={})
    assert not bad_deps.ok
    assert bad_deps.gap_event["details"]["fail_stage"] == "deps"

    pack_incompatible = base / "regart-incompatible"
    shutil.copytree(source_pack, pack_incompatible)
    bad_core = rt.install_pack_from_dir(
        pack_incompatible,
        catalog={"base-observability": ["1.0.0"]},
        core_version="9.0.0",
    )
    assert not bad_core.ok
    assert bad_core.gap_event["kind"] == "observability_gap.pack_incompatible"

print("pack install runtime: OK")
PY
