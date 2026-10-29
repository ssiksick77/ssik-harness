# ssik-harness

Claude Code로 바이브코딩할 때 쓰는 작업 규칙 묶음(하네스)입니다. 규칙(`CLAUDE.md`), 절차(`.claude/skills/`), 프로젝트 템플릿(`_template/`), 세션 시작 hook을 한 폴더에 모아 두고, 프로젝트마다 바로가기로 연결해 씁니다.

이 하네스는 제작자 한 사람의 작업 방식에 맞춰 만든 것입니다. 한국어 UI 규칙(KRDS), Windows + Git Bash, 프로젝트마다 비공개 GitHub 저장소, 매 변경마다 `scripts/check.sh` 같은 선택은 제작자의 필요에서 나왔습니다. 그대로 써도 되지만, 맞지 않는 부분은 바꿔 쓰는 것이 전제입니다. 어디를 바꾸면 되는지는 아래 "바꿔 쓰기"에 있습니다.

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

## 바꿔 쓰기

모두 글 파일과 짧은 bash 스크립트입니다. 고친 뒤 `bash scripts/selftest.sh`로 깨진 곳이 없는지 확인하세요.

| 바꾸고 싶은 것 | 어디를 고치나 |
|---|---|
| 작업 규칙(질문 시점, 커밋 절차, 검사 기준) | `CLAUDE.md`. 프로젝트 하나에만 적용할 규칙은 그 프로젝트의 `CLAUDE.md` |
| 절차(브레인스토밍, 새 프로젝트, 마무리) | `.claude/skills/<이름>/SKILL.md`. 안 쓰는 스킬은 폴더째 지워도 됩니다 |
| 세션 시작 때 보여 주는 정보 | `.claude/hooks/session-start.sh` |
| 새 프로젝트의 기본 파일 | `_template/` |
| UI 규칙(KRDS 사용 여부, 디자인 스킬) | `_template/DESIGN.md`의 KRDS 모드. KRDS가 필요 없으면 `ui-work`·`krds-*`·`_tools/future-krds`를 빼도 됩니다 |
| GitHub 저장소를 자동으로 만들지 않기 | `new-project` 스킬의 `gh repo create` 단계 |
| Mac / Linux | 그대로 동작합니다. 개발자 모드 단계만 건너뛰세요 |

## 외부 자료

- `.claude/skills/impeccable` — Apache 2.0
- `.claude/skills/break-ui` — MIT ([VENDOR.md](.claude/skills/break-ui/VENDOR.md))
- `_tools/future-krds` — [humantonylee/future-krds](https://github.com/humantonylee/future-krds)
