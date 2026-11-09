"""loom guard. stdin: PreToolUse JSON. argv[1]: the worktree (cwd). Exit 2 blocks."""
import json, os, re, shlex, sys

LOCAL = re.compile(r'(^|://|@)(localhost|127\.0\.0\.1|0\.0\.0\.0|\[::1\]|[\w.-]+\.local)([:/]|$)')
NET_TOOLS = {'curl', 'wget', 'http', 'https', 'httpie', 'xh'}
WRITE_FLAGS = {'-d', '--data', '--data-raw', '--data-binary', '--data-urlencode', '--data-ascii', '-F', '--form',
               '-T', '--upload-file', '--json', '--post-data', '--post-file', '--method'}
BLOCK_FIRST = {'gh', 'glab', 'hub', 'kubectl', 'helm', 'terraform', 'pulumi', 'serverless', 'sls', 'vercel',
               'netlify', 'fly', 'flyctl', 'heroku', 'wrangler', 'aws', 'gcloud', 'az', 'ssh', 'scp', 'sftp',
               'rsync', 'nc', 'ncat', 'netcat', 'twine', 'gem'}
PKG = {'npm', 'yarn', 'pnpm', 'bun', 'cargo'}

def block(msg):
    sys.stderr.write(f"loom run: blocked — {msg}. A run never pushes, publishes, deploys, writes to a remote, "
                     f"or leaves its worktree. Put what wanted it under Open: in the report.\n")
    sys.exit(2)

HEREDOC = re.compile(r"<<-?\s*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\1")
INTERP = {'sh', 'bash', 'zsh', 'dash', 'ksh', 'python', 'python3', 'node', 'perl', 'ruby', 'php'}

def split_heredocs(cmd):
    """Drop heredoc bodies from the command text; return them with their head line."""
    lines = cmd.split('\n'); out = []; bodies = []; i = 0
    while i < len(lines):
        line = lines[i]; m = HEREDOC.search(line)
        if not m: out.append(line); i += 1; continue
        term = m.group(2); out.append(line[:m.start()] + ' ' + line[m.end():]); body = []; i += 1
        while i < len(lines) and lines[i].strip() != term: body.append(lines[i]); i += 1
        bodies.append((line[:m.start()], '\n'.join(body))); i += 1
    return '\n'.join(out), bodies

def tokens(seg):
    for posix in (True, False):
        try: return shlex.split(seg, posix=posix)
        except ValueError: pass
    return seg.split()

def segments(cmd):
    return [s.strip() for s in re.split(r'\|\||&&|;|\||\n|\$\(|`', cmd) if s.strip()]

def strip_prefix(tok):
    while tok and (tok[0] in ('sudo', 'time', 'nohup', 'exec', 'command', 'env') or re.match(r'^[A-Za-z_]\w*=', tok[0])):
        tok = tok[1:]
    return tok

def git_sub(tok):
    i = 1
    while i < len(tok) and tok[i].startswith('-'):
        if tok[i] in ('-C', '-c', '--git-dir', '--work-tree', '--namespace'): i += 2
        else: i += 1
    return tok[i:] if i < len(tok) else []

def check(tok):
    if not tok: return
    head = tok[0]
    if head == 'git':
        sub = git_sub(tok); s = sub[0] if sub else ''; rest = sub[1:]
        if s in ('push', 'send-pack', 'update-ref', 'worktree', 'merge', 'rebase', 'switch'): block(f"git {s}")
        if s == 'remote' and rest and rest[0] in ('add', 'set-url', 'rm', 'remove', 'rename'): block("git remote change")
        if s == 'reset' and '--hard' in rest: block("git reset --hard")
        if s == 'branch' and any(r in ('-D', '-d', '--delete', '-M', '-m') for r in rest): block("git branch delete/rename")
        if s == 'checkout' and '--' not in rest: block("git checkout <branch>; use `git checkout -- <file>`")
        if s == 'config' and any(r in ('--global', '--system') for r in rest): block("git config outside the repo")
        if any(t.startswith('-C') or t in ('--git-dir',) for t in tok[1:]) and any('..' in t for t in tok): block("git reaching outside the worktree")
        return
    if head in BLOCK_FIRST: block(head)
    if head in PKG and any(t in ('publish', 'deploy', 'release') for t in tok[1:]): block(f"{head} publish/deploy")
    if head == 'make' and any(t in ('deploy', 'publish', 'release') for t in tok[1:]): block("make deploy")
    if head == 'docker' and len(tok) > 1 and tok[1] in ('push', 'login', 'logout'): block("docker push/login")
    if head == 'docker' and 'prune' in tok[1:]: block("docker prune — a run never tidies the host; a full disk is `blocked: disk`")
    if head == 'go' and len(tok) > 2 and tok[1] == 'clean' and any(t in ('-cache', '-modcache') for t in tok[2:]): block("go clean -cache/-modcache — a run never tidies the host")
    if head in NET_TOOLS:
        writes = any(t in WRITE_FLAGS or t.startswith(('--data', '--form', '--upload-file', '--json', '--post-')) for t in tok[1:])
        meth = any(t in ('-X', '--request') and i + 1 < len(tok) and tok[i + 1].upper() in ('POST', 'PUT', 'PATCH', 'DELETE') for i, t in enumerate(tok))
        if head in ('http', 'https', 'xh', 'httpie') and any(t.upper() in ('POST', 'PUT', 'PATCH', 'DELETE') for t in tok[1:]): meth = True
        urls = [t for t in tok[1:] if '://' in t or re.match(r'^[\w.-]+\.[a-z]{2,}(/|$)', t) or t.startswith(('localhost', '127.'))]
        if (writes or meth) and not (urls and all(LOCAL.search(u) for u in urls)): block(f"{head} write to a non-local address")

def main():
    try:
        ev = json.load(sys.stdin)
    except Exception:
        block("unparseable tool input")
    name = ev.get('tool_name', ''); inp = ev.get('tool_input', {}) or {}
    wt = os.path.realpath(sys.argv[1] if len(sys.argv) > 1 else os.getcwd())
    if name in ('Write', 'Edit', 'MultiEdit', 'NotebookEdit'):
        p = inp.get('file_path') or inp.get('notebook_path') or ''
        if p and os.path.isabs(p) and not os.path.realpath(p).startswith(wt + os.sep): block(f"write outside the worktree: {p}")
        return
    if name != 'Bash': return
    cmd, bodies = split_heredocs(inp.get('command', ''))
    for seg in segments(cmd): check(strip_prefix(tokens(seg)))
    for head, body in bodies:                      # a heredoc body is data — unless an interpreter eats it
        if any(t in INTERP for t in strip_prefix(tokens(head))[:3]):
            for seg in segments(body): check(strip_prefix(tokens(seg)))

main()
