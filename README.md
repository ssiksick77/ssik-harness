# ssik-harness

Claude Code로 바이브코딩할 때 쓰는 작업 규칙 묶음(하네스)입니다. 규칙(`CLAUDE.md`), 절차(`.claude/skills/`), 프로젝트 템플릿(`_template/`), 세션 시작 hook을 한 폴더에 모아 두고, 프로젝트마다 바로가기로 연결해 씁니다.

처음이라면 [docs/harness-guide.html](docs/harness-guide.html)을 브라우저로 열어 읽으세요. 빈 Windows PC에서 첫 프로젝트까지 따라 할 수 있게 썼습니다.

## 빠른 시작 (Windows, Git Bash)

```bash
mkdir -p ~/Desktop/Project && cd ~/Desktop/Project
git clone https://github.com/ssiksick77/ssik-harness.git DEV
cd DEV
scripts/setup.sh   # 시작 마법사: 폴더 이름을 정하고, 설치 상태를 검사해 빠진 것을 알려 줍니다
claude             # 그다음 /start 라고 치세요
```

폴더 이름 `DEV`는 기본값일 뿐입니다. 마법사가 처음에 이름을 묻고(Enter면 그대로) 원하는 이름으로 바꿔 줍니다. 이 문서의 `DEV/`는 그 하네스 폴더를 뜻합니다.

필요한 것: Git for Windows(Git Bash), GitHub 계정과 `gh`, Claude Code, Windows 개발자 모드(바로가기용). 마법사가 하나씩 확인합니다.

## 폴더

| 경로 | 역할 |
|---|---|
| `CLAUDE.md` | 모든 프로젝트에 적용되는 규칙 |
| `.claude/skills/` | 절차: `start`, `brainstorm`, `new-project`, `adopt-project`, `wrap-up`, `migrate`, `ui-work` 등 |
| `.claude/hooks/session-start.sh` | 세션 시작 시 진행 상태를 읽어 주는 hook |
| `_template/` | 새 프로젝트 템플릿 (`progress.md`, `ideas.md`, `scripts/check.sh`) |
| `_group-template/` | 프로젝트 묶음(그룹) 템플릿 |
| `_tools/future-krds` | KRDS 디자인 참고 자료 (서브모듈) |
| `scripts/` | `setup.sh`(시작 마법사), `selftest.sh`, `release.sh` |
| `migrations/` | 하네스 버전 올릴 때 프로젝트에 적용할 변경 |

프로젝트는 `DEV/<이름>/`에 생기고 각자 자기 git 저장소를 가집니다. 이 저장소는 하네스만 추적합니다.

## 외부 자료

- `.claude/skills/impeccable` — Apache 2.0
- `.claude/skills/break-ui` — MIT ([VENDOR.md](.claude/skills/break-ui/VENDOR.md))
- `_tools/future-krds` — [humantonylee/future-krds](https://github.com/humantonylee/future-krds)
