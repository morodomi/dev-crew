#!/usr/bin/env python3
"""公開 repo（dev-crew）への固有名・実 path の混入を止める PreToolUse hook（ADR-005）。

stdin の hook 入力 JSON からコマンドを読み、shell と同じ規則で引数に分解して、
git commit / git push / gh pr|issue create|edit|comment ごとに検査する。
止めるときは exit 2。対象の操作を含むのに検査できなかった場合も exit 2（検査できないものは通さない）。

環境変数:
  DEV_CREW_LEAK_DENYLIST   禁止語リスト（既定 ~/.config/dev-crew/project-labels.tsv。tab 区切りなら 2 列目、
                           そうでなければ行全体。# で始まる行は無視）。無ければ禁止語の検査は skip する
  DEV_CREW_LEAK_GUARD_REPO 保護する repo の root（既定はこのスクリプトがある repo）
"""
import json
import os
import re
import shlex
import subprocess
import sys

# ホーム直下の実 path。ドットで始まる階層（plan_file が使う ~/.claude/plans など）は許可する
PATH_RE = re.compile(r"/(Users|home)/[^/\s]+/[^./\s]")
OPERATORS = {"&&", "||", ";", "|", "&", "(", ")", ";;", "|&"}
TRIGGER_RE = re.compile(r"\bgit\b[^\n]*\b(commit|push)\b|\bgh\b[^\n]*\b(pr|issue)\b")
GIT_OPTS_WITH_VALUE = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path"}


def run_git(cwd, *args):
    out = subprocess.run(["git", "-C", cwd, *args], capture_output=True, text=True)
    if out.returncode != 0:
        raise RuntimeError("git " + args[0] + " failed")
    return out.stdout


def toplevel(path):
    try:
        top = run_git(path, "rev-parse", "--show-toplevel").strip()
    except (RuntimeError, OSError):
        return None
    return os.path.realpath(top)


def resolve(base, path):
    return os.path.realpath(os.path.join(base, os.path.expanduser(path)))


def added_lines(diff_text, label_prefix=""):
    """diff から追加行だけを (ファイル名, 行) で返す。hunk の中の '+' だけを追加行とみなす。"""
    current, in_hunk = "", False
    for line in diff_text.splitlines():
        if line.startswith("diff --git ") or line.startswith("commit "):
            in_hunk = False
            continue
        if not in_hunk and line.startswith("+++ "):
            current = line[4:]
            current = current[2:] if current.startswith("b/") else current
            continue
        if line.startswith("@@"):
            in_hunk = True
            continue
        if in_hunk and line.startswith("+"):
            yield (label_prefix + current, line[1:])


def file_lines(label, path):
    with open(path, encoding="utf-8", errors="replace") as fh:
        return [(label, ln) for ln in fh.read().splitlines()]


REDIRECT_RE = re.compile(r"^[<>]+&?$|^>&$|^&>>?$")


def split_segments(cmd):
    lexer = shlex.shlex(cmd, posix=True, punctuation_chars=True)
    lexer.whitespace_split = True
    segment = []
    drop_next = False
    for tok in lexer:
        if drop_next:
            drop_next = False
            continue
        if tok in OPERATORS:
            if segment:
                yield segment
            segment = []
        elif REDIRECT_RE.match(tok):
            # `2>&1` は shlex で '2' '>&' '1' に分かれる。fd 番号と行き先を引数として扱わない
            if segment and segment[-1].isdigit():
                segment.pop()
            drop_next = True
        else:
            segment.append(tok)
    if segment:
        yield segment


def option_values(args, names):
    """`--opt value` / `--opt=value` / `-o value` の value を返す。"""
    values = []
    for i, a in enumerate(args):
        for n in names:
            if a == n and i + 1 < len(args):
                values.append(args[i + 1])
            elif n.startswith("--") and a.startswith(n + "="):
                values.append(a[len(n) + 1:])
    return values


def git_push_sources(top, args):
    positional = []
    skip = False
    for a in args:
        if skip:
            skip = False
            continue
        if a in ("-o", "--push-option", "--repo", "--receive-pack", "--exec"):
            skip = True
            continue
        if a.startswith("-"):
            continue
        positional.append(a)
    remote = positional[0] if positional else "origin"
    refspecs = positional[1:] or ["HEAD"]
    sources = []
    for spec in refspecs:
        spec = spec.lstrip("+")
        src, _, dst = spec.partition(":")
        src = src or "HEAD"
        branch = dst or (src if src != "HEAD" else run_git(top, "rev-parse", "--abbrev-ref", "HEAD").strip())
        branch = branch.replace("refs/heads/", "")
        base = None
        for candidate in (f"{remote}/{branch}", f"{src}@{{u}}", f"{remote}/main", "origin/main"):
            ok = subprocess.run(["git", "-C", top, "rev-parse", "-q", "--verify", candidate],
                                capture_output=True, text=True)
            if ok.returncode == 0:
                base = candidate
                break
        if base is None:
            raise RuntimeError("push base not found")
        # 追加して後の commit で消した場合も公開されるので、集約 diff ではなく commit ごとに見る
        commits = run_git(top, "rev-list", "--reverse", f"{base}..{src}").split()
        for c in commits:
            msg = run_git(top, "log", "-1", "--format=%B", c)
            sources += [("commit message", ln) for ln in msg.splitlines()]
            sources += list(added_lines(run_git(top, "show", "--format=", "-U0", "--no-color", c)))
    return sources


def collect(segments, cwd, protected):
    """保護対象の repo に向いた操作ごとに、検査する (場所, 行) を集める。"""
    sources, texts = [], []
    pending_add = []
    for seg in segments:
        if seg[0] == "cd":
            cwd = resolve(cwd, seg[1] if len(seg) > 1 else "~")
            continue
        if seg[0] == "git":
            opdir, i = cwd, 1
            while i < len(seg) and seg[i].startswith("-"):
                if seg[i] == "-C" and i + 1 < len(seg):
                    opdir = resolve(opdir, seg[i + 1])
                if seg[i] in GIT_OPTS_WITH_VALUE:
                    i += 1
                i += 1
            if i >= len(seg):
                continue
            sub, args = seg[i], seg[i + 1:]
            top = toplevel(opdir)
            if top != protected:
                continue
            if sub == "add":
                specs = [a for a in args if not a.startswith("-")]
                if any(a in ("-A", "--all") for a in args) or not specs and "-u" not in args:
                    specs = [":/"]
                for spec in specs:
                    out = run_git(opdir, "ls-files", "--others", "--exclude-standard", "--full-name", "--", spec)
                    pending_add += [f for f in out.splitlines() if f]
            elif sub == "commit":
                diff = run_git(top, "diff", "--cached", "-U0", "--no-color") + run_git(top, "diff", "-U0", "--no-color")
                sources += list(added_lines(diff))
                for f in pending_add:
                    sources += file_lines(f, os.path.join(top, f))
                texts += option_values(args, ["-m", "--message"])
                texts += [a[2:] for a in args if a.startswith("-m") and len(a) > 2 and not a.startswith("--")]
                for f in option_values(args, ["-F", "--file"]):
                    sources += file_lines("commit message file", resolve(opdir, f))
            elif sub == "push":
                sources += git_push_sources(top, args)
            continue
        if seg[0] == "gh":
            repos = option_values(seg, ["-R", "--repo"])
            if len(seg) < 3:
                continue
            rest = [a for a in seg[1:]]
            # -R / --repo は位置を問わず受け付ける
            nouns = [a for a in rest if a in ("pr", "issue")]
            if not nouns:
                continue
            idx = rest.index(nouns[0])
            action = rest[idx + 1] if idx + 1 < len(rest) else ""
            if action not in ("create", "edit", "comment"):
                continue
            if repos:
                if not all(r.rstrip("/").split("/")[-1] == "dev-crew" for r in repos):
                    continue
            elif toplevel(cwd) != protected:
                continue
            texts += option_values(rest, ["--body", "-b", "--title", "-t"])
            for f in option_values(rest, ["--body-file", "-F"]):
                sources += file_lines("body file", resolve(cwd, f))
    return sources, texts


def load_denylist(path):
    if not os.path.isfile(path):
        return []
    tokens = []
    with open(path, encoding="utf-8", errors="replace") as fh:
        for n, line in enumerate(fh.read().splitlines(), 1):
            if not line or line.startswith("#"):
                continue
            token = line.split("\t")[1] if "\t" in line else line
            token = token.strip()
            if len(token) >= 3:
                tokens.append((n, token.lower()))
    return tokens


def redact(label, tokens):
    for _, tok in tokens:
        label = re.sub(re.escape(tok), "***", label, flags=re.IGNORECASE)
    return label


def main():
    if len(sys.argv) < 2 or sys.argv[1] != "hook":
        print("usage: leak-guard.sh hook", file=sys.stderr)
        return 64
    raw = sys.stdin.read()
    try:
        data = json.loads(raw) if raw.strip() else {}
        cmd = (data.get("tool_input") or {}).get("command") or ""
        cwd = data.get("cwd") or os.getcwd()
    except (ValueError, AttributeError):
        cmd, cwd = raw, os.getcwd()
    if not TRIGGER_RE.search(cmd):
        return 0

    here = os.path.dirname(os.path.abspath(__file__))
    protected = os.path.realpath(os.environ.get("DEV_CREW_LEAK_GUARD_REPO") or os.path.join(here, "..", ".."))
    tokens = load_denylist(os.environ.get("DEV_CREW_LEAK_DENYLIST")
                           or os.path.join(os.path.expanduser("~"), ".config", "dev-crew", "project-labels.tsv"))
    try:
        sources, texts = collect(list(split_segments(cmd)), cwd, protected)
    except Exception as exc:  # 検査できないものは通さない
        print(f"BLOCKED (leak-guard, ADR-005): 検査できなかった（{type(exc).__name__}）。"
              "コマンドを単純な形に分けて再実行する", file=sys.stderr)
        return 2

    hits = set()
    for text in texts:
        low = text.lower()
        for n, tok in tokens:
            if tok in low:
                hits.add(f"コマンドの本文: 禁止語リスト {n} 行目")
        if PATH_RE.search(text):
            hits.add("コマンドの本文: ホーム直下の実 path")
    for label, line in sources:
        low = line.lower() + "\n" + label.lower()
        for n, tok in tokens:
            if tok in low:
                hits.add(f"{redact(label, tokens)}: 禁止語リスト {n} 行目")
        if PATH_RE.search(line):
            hits.add(f"{redact(label, tokens)}: ホーム直下の実 path")
    if hits:
        print("BLOCKED (leak-guard, ADR-005): 公開 repo に固有名か実 path が入ろうとしている", file=sys.stderr)
        for h in sorted(hits):
            print(f"  - {h}", file=sys.stderr)
        print("該当箇所を匿名ラベルや変数表記（$HOME など）に書き換えてから再実行する。禁止語そのものは出力しない",
              file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
