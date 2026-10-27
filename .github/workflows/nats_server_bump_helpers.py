"""Discover NATS releases and prepare narrowly scoped Helm chart updates.

YAML source locations preserve comments and formatting while validation prevents
ambiguous edits. GitHub access uses gh; Docker Hub checks use the standard library.
"""

from __future__ import annotations

import difflib
import json
import subprocess
from dataclasses import dataclass
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

import yaml
from yaml.nodes import MappingNode, Node, ScalarNode, SequenceNode


@dataclass
class _Document:
    """Keep a YAML document's source and validated parser locations together."""

    path: Path
    text: str
    root: MappingNode
    shared_nodes: set[int]


def parse_version(value: str) -> tuple[int, int, int]:
    """Parse a canonical stable version without a tag prefix or suffix.

    Args:
        value: A version in X.Y.Z form.

    Returns:
        Numeric major, minor, and patch components.

    Raises:
        ValueError: The value is not a canonical stable version.
    """
    parts = value.split(".")
    if len(parts) != 3 or any(
        not part.isascii() or not part.isdecimal() or (len(part) > 1 and part.startswith("0"))
        for part in parts
    ):
        raise ValueError(f"Expected a stable X.Y.Z version, got {value!r}")
    return int(parts[0]), int(parts[1]), int(parts[2])


def _validate_tree(root: MappingNode, path: Path) -> set[int]:
    """Reject duplicate mapping keys and identify nodes shared through aliases."""
    seen: set[int] = set()
    shared: set[int] = set()
    pending: list[Node] = [root]
    while pending:
        node = pending.pop()
        if id(node) in seen:
            shared.add(id(node))
            continue
        seen.add(id(node))
        if isinstance(node, MappingNode):
            keys: set[str] = set()
            for key, value in node.value:
                if not isinstance(key, ScalarNode) or key.tag != "tag:yaml.org,2002:str":
                    raise ValueError(f"{path}: expected string mapping keys at line {key.start_mark.line + 1}")
                if key.value in keys:
                    raise ValueError(f"{path}: duplicate key {key.value!r} at line {key.start_mark.line + 1}")
                keys.add(key.value)
                pending.append(value)
        elif isinstance(node, SequenceNode):
            pending.extend(node.value)
    return shared


def _parse_document(path: Path, text: str) -> _Document:
    """Parse one YAML mapping without constructing arbitrary Python objects."""
    try:
        root = yaml.compose(text, Loader=yaml.SafeLoader)
    except yaml.YAMLError as exc:
        mark = getattr(exc, "problem_mark", None)
        location = f" at line {mark.line + 1}, column {mark.column + 1}" if mark else ""
        raise ValueError(f"{path}: invalid YAML{location}") from exc
    if not isinstance(root, MappingNode):
        raise ValueError(f"{path}: expected a single YAML mapping")
    return _Document(path, text, root, _validate_tree(root, path))


def _read_document(path: Path) -> _Document:
    """Read UTF-8 YAML while preserving its original line endings."""
    try:
        with path.open(encoding="utf-8", newline="") as source:
            return _parse_document(path, source.read())
    except (OSError, UnicodeError) as exc:
        raise ValueError(f"{path}: could not read UTF-8 YAML") from exc


def _scalar(document: _Document, keys: tuple[str, ...]) -> ScalarNode:
    """Locate an unambiguous string field suitable for a source replacement."""
    node: Node = document.root
    field = ".".join(keys)
    for key in keys:
        if id(node) in document.shared_nodes or not isinstance(node, MappingNode):
            raise ValueError(f"{document.path}: {field} must belong to ordinary, unaliased mappings")
        matches = [value for name, value in node.value if name.value == key]
        if not matches:
            raise ValueError(f"{document.path}: missing {field}")
        node = matches[0]
    if id(node) in document.shared_nodes:
        raise ValueError(f"{document.path}: {field} must not use an alias or shared anchor")
    if not isinstance(node, ScalarNode) or node.tag != "tag:yaml.org,2002:str" or node.style not in (None, "'", '"'):
        raise ValueError(f"{document.path}: {field} must be a plain or quoted string")
    raw = document.text[node.start_mark.index:node.end_mark.index]
    if "\n" in raw or "\r" in raw or raw.startswith(("&", "!")):
        raise ValueError(f"{document.path}: {field} must be a single-line string without anchors or explicit tags")
    return node


def _chart_documents(chart_dir: Path) -> tuple[_Document, _Document, str, str]:
    """Load chart inputs and require the official image to match appVersion."""
    chart = _read_document(chart_dir / "Chart.yaml")
    values = _read_document(chart_dir / "values.yaml")
    current = _scalar(chart, ("appVersion",)).value
    version = _scalar(chart, ("version",)).value
    for field, value in (("appVersion", current), ("version", version)):
        try:
            parse_version(value)
        except ValueError as exc:
            raise ValueError(f"{chart.path}: {field}: {exc}") from exc
    repository = _scalar(values, ("container", "image", "repository")).value
    image_tag = _scalar(values, ("container", "image", "tag")).value
    if repository != "nats":
        raise ValueError(f"{values.path}: container.image.repository must be 'nats'")
    if image_tag != f"{current}-alpine":
        raise ValueError(f"{values.path}: container.image.tag must match appVersion ({current}-alpine)")
    return chart, values, current, version


def latest_release() -> str:
    """Fetch all release pages with gh and select the highest stable version.

    Returns:
        The highest published stable X.Y.Z version, without its v prefix.

    Raises:
        RuntimeError: GitHub access fails or returns malformed or unusable data.
    """
    command = [
        "gh", "api", "--hostname", "github.com", "--paginate", "--slurp",
        "repos/nats-io/nats-server/releases?per_page=100",
    ]
    try:
        result = subprocess.run(command, check=True, capture_output=True, text=True, timeout=120)
    except FileNotFoundError as exc:
        raise RuntimeError("GitHub release lookup requires gh on PATH") from exc
    except subprocess.TimeoutExpired as exc:
        raise RuntimeError("GitHub release lookup timed out after 120 seconds") from exc
    except subprocess.CalledProcessError as exc:
        # gh stderr can contain HTTP debug output; never copy it into CI logs.
        raise RuntimeError(f"GitHub release lookup failed (gh exit {exc.returncode}); check authentication, rate limits, and connectivity") from exc
    except OSError as exc:
        raise RuntimeError("Could not execute gh for GitHub release lookup") from exc
    try:
        pages = json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        raise RuntimeError("GitHub release lookup returned invalid JSON") from exc
    if not isinstance(pages, list) or any(not isinstance(page, list) for page in pages):
        raise RuntimeError("GitHub release lookup expected an array of release pages")
    versions: dict[tuple[int, int, int], str] = {}
    for page in pages:
        for release in page:
            if (
                not isinstance(release, dict)
                or type(release.get("draft")) is not bool
                or type(release.get("prerelease")) is not bool
                or not isinstance(release.get("tag_name"), str)
            ):
                raise RuntimeError("GitHub release lookup returned a malformed release")
            tag = release["tag_name"]
            if release["draft"] or release["prerelease"] or not tag.startswith("v"):
                continue
            try:
                version = parse_version(tag[1:])
            except ValueError:
                continue
            versions[version] = tag[1:]
    if not versions:
        raise RuntimeError("GitHub has no published stable vX.Y.Z nats-server releases")
    return versions[max(versions)]


def image_available(version: str) -> bool:
    """Check whether Docker Hub publishes the official Alpine image tag.

    Args:
        version: A canonical X.Y.Z server version.

    Returns:
        True for HTTP 200, or False for HTTP 404 (publication is pending).

    Raises:
        ValueError: The version is invalid.
        RuntimeError: The request fails or returns any other status.
    """
    parse_version(version)
    request = Request(
        f"https://hub.docker.com/v2/repositories/library/nats/tags/{version}-alpine",
        headers={"User-Agent": "nats-k8s-server-bump"},
    )
    try:
        with urlopen(request, timeout=30) as response:
            status = response.status
    except HTTPError as exc:
        status = exc.code
        exc.close()
    except (URLError, OSError) as exc:
        raise RuntimeError(f"Docker Hub lookup for nats:{version}-alpine failed; check connectivity and TLS") from exc
    if status == 404:
        return False
    if status != 200:
        raise RuntimeError(f"Docker Hub lookup for nats:{version}-alpine returned HTTP {status}")
    return True


def check_bump(chart_dir: Path) -> dict[str, str]:
    """Check release and image availability without editing chart files.

    Args:
        chart_dir: Directory containing Chart.yaml and values.yaml.

    Returns:
        GitHub Actions outputs, including bump=false for expected no-ops.

    Raises:
        ValueError: Chart contents are invalid or its version cannot advance.
        RuntimeError: Release or image discovery fails.
    """
    _, _, current, chart_version = _chart_documents(chart_dir)
    latest = latest_release()
    print(f"appVersion    : {current}\nchart version : {chart_version}\nlatest        : {latest}")
    if parse_version(current) >= parse_version(latest):
        print(f"Chart already at {current}; nothing to do")
        return {"bump": "false"}
    if parse_version(chart_version) >= parse_version(latest):
        raise ValueError(f"Chart version {chart_version} is not below {latest}; a chart-only bump needs manual handling")
    if not image_available(latest):
        print(f"Image nats:{latest}-alpine is not published yet; waiting")
        return {"bump": "false"}
    print(f"Image nats:{latest}-alpine is available")
    return {"bump": "true", "current": current, "latest": latest, "image_tag": f"{latest}-alpine"}


def _replace_values(document: _Document, replacements: dict[tuple[str, ...], str]) -> str:
    """Replace validated scalars from right to left and reparse the result."""
    edits: list[tuple[int, int, str]] = []
    for keys, value in replacements.items():
        node = _scalar(document, keys)
        quote = node.style or ""
        edits.append((node.start_mark.index, node.end_mark.index, f"{quote}{value}{quote}"))
    updated = document.text
    for start, end, replacement in sorted(edits, reverse=True):
        updated = updated[:start] + replacement + updated[end:]
    parsed = _parse_document(document.path, updated)
    for keys, value in replacements.items():
        if _scalar(parsed, keys).value != value:
            raise ValueError(f"{document.path}: failed to verify {'.'.join(keys)} after editing")
    return updated


def update_chart(chart_dir: Path, current: str, latest: str, dry_run: bool = False) -> None:
    """Validate and update the three chart fields, or print their proposed diff.

    Args:
        chart_dir: Directory containing Chart.yaml and values.yaml.
        current: Expected current appVersion from the check command.
        latest: Selected target X.Y.Z version from the check command.
        dry_run: Print the diff without writing either file.

    Raises:
        ValueError: Versions or YAML contents do not satisfy update preconditions.
        OSError: A file cannot be written; an earlier file may already be updated.
    """
    if parse_version(latest) <= parse_version(current):
        raise ValueError(f"Target version {latest} must be newer than {current}")
    chart, values, actual, chart_version = _chart_documents(chart_dir)
    if actual != current:
        raise ValueError(f"{chart.path}: appVersion changed; expected {current}, found {actual}")
    if parse_version(chart_version) >= parse_version(latest):
        raise ValueError(f"{chart.path}: version {chart_version} must be below target {latest}")
    changes = [
        (chart, _replace_values(chart, {("appVersion",): latest, ("version",): latest})),
        (values, _replace_values(values, {("container", "image", "tag"): f"{latest}-alpine"})),
    ]
    # Prepare and verify both documents before writing either one.
    for document, updated in changes:
        if dry_run:
            diff = difflib.unified_diff(
                document.text.splitlines(keepends=True), updated.splitlines(keepends=True),
                fromfile=str(document.path), tofile=str(document.path),
            )
            print("".join(diff), end="")
        else:
            with document.path.open("w", encoding="utf-8", newline="") as destination:
                destination.write(updated)
            print(f"Updated {document.path}")
