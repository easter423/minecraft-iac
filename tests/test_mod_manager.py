from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import scripts.mod_manager as mm  # noqa: E402


class DummyResp:
    def __init__(self, content: bytes):
        self._content = content

    def iter_content(self, chunk_size=8192):
        yield self._content

    def raise_for_status(self):
        pass

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        pass


def test_sha256_from_url(monkeypatch):
    def fake_get(url, stream=False):
        return DummyResp(b"test")

    monkeypatch.setattr(mm.requests, "get", fake_get)
    expected = (
        "sha256:9f86d081884c7d659a2feaa0c55ad015"
        "a3bf4f1b2b0b822cd15d6c15b0f00a08"
    )
    assert mm.sha256_from_url("http://example.com") == expected
