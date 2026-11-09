"""Package only a fresh Windows release directory, never a used installation."""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]

def main():
    version = re.search(r'^version: (\d+\.\d+\.\d+)\+(\d+)$', (ROOT / 'pubspec.yaml').read_text(encoding='utf-8'), re.M)
    if not version:
        raise RuntimeError('Invalid version')
    release = ROOT / 'build/windows/x64/runner/Release'
    for required in ['speakr_app.exe', 'flutter_windows.dll', 'data/app.so', 'data/icudtl.dat']:
        if not (release / required).is_file():
            raise RuntimeError(f'Missing application file: {required}')
    files = sorted(p for p in release.rglob('*') if p.is_file())
    forbidden = {'.db', '.sqlite', '.sqlite3', '.log', '.pdb', '.m4a', '.wav', '.mp3', '.mp4'}
    for path in files:
        if path.is_symlink() or path.suffix.lower() in forbidden or any(s in path.name.lower() for s in ['shared_preferences', 'secure_storage.json', '.env']):
            raise RuntimeError(f'Unexpected runtime or development file: {path.name}')
        data = path.read_bytes()
        for encoding in ['utf-8', 'utf-16le']:
            text = data.decode(encoding, errors='ignore')
            if re.search(r'gh[pousr]_[A-Za-z0-9]{25,}|github_pat_[A-Za-z0-9_]{30,}|-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----', text):
                raise RuntimeError(f'Credential pattern in {path.name}')
    dist = ROOT / 'dist'
    dist.mkdir(exist_ok=False)
    commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    run_id = os.environ.get('GITHUB_RUN_ID')
    repo = os.environ.get('GITHUB_REPOSITORY', 'i-iooi-i/Mimio')
    metadata = {
        'version': version[1], 'build_number': version[2], 'source_commit': commit,
        'repository': f'https://github.com/{repo}',
        'workflow_run': f'https://github.com/{repo}/actions/runs/{run_id}' if run_id else None,
        'flutter': json.loads(subprocess.check_output(['flutter', '--version', '--machine'], shell=os.name == 'nt', text=True)),
    }
    archive = dist / f'Mimio-{version[1]}-windows-x64.zip'
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as output:
        for path in files:
            name = path.relative_to(release).as_posix()
            if name == 'speakr_app.exe':
                name = 'Mimio.exe'
            output.write(path, 'Mimio/' + name)
        output.write(ROOT / 'LICENSE', 'Mimio/LICENSE')
        output.writestr('Mimio/BUILD-INFO.json', json.dumps(metadata, ensure_ascii=False, indent=2))
        output.writestr('Mimio/使用说明.txt', f'Mimio {version[1]} Windows x64\n完整解压后运行 Mimio.exe。\n需要自己的 Speakr 服务器和 API 令牌。\n本包不含个人配置或录音。升级前请备份旧程序目录。\nWindows 程序未签名。\nhttps://github.com/i-iooi-i/Mimio\n')
    with zipfile.ZipFile(archive) as check:
        if check.testzip() is not None:
            raise RuntimeError('ZIP integrity check failed')
        for path in files:
            name = path.relative_to(release).as_posix()
            if name == 'speakr_app.exe':
                name = 'Mimio.exe'
            if hashlib.sha256(check.read('Mimio/' + name)).digest() != hashlib.sha256(path.read_bytes()).digest():
                raise RuntimeError('ZIP content differs from build')
    (dist / 'BUILD-INFO.json').write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    sums = ''.join(f'{hashlib.sha256(p.read_bytes()).hexdigest()}  {p.name}\n' for p in sorted(dist.iterdir()))
    (dist / 'SHA256SUMS.txt').write_text(sums, encoding='utf-8')
    print(f'Packaged {len(files)} application files: {archive.name}')

if __name__ == '__main__':
    main()
