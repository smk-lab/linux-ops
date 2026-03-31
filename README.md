# 🛠️ Ops-Automation-Scripts

운영 환경 관리 및 자동화를 위한 Bash 스크립트 저장소입니다.  
`hosts.ini` 파일을 통해 대상 서버를 관리하며, 민감 정보는 저장소에 포함하지 않습니다.

---

## 📁 디렉토리 구조

```
ops-scripts/
├── linux/              # Linux 서버 모니터링 및 tmux 세션 관리
├── hosts.ini.example   # 서버 목록 템플릿 (실제 값 없음)
├── .gitignore
└── README.md
```

> 이후 `openstack/`, `kolla/`, `network/` 등의 디렉토리가 추가될 예정입니다.

---

## ⚙️ 시작하기

### 1. 저장소 클론 후 hosts.ini 생성

```bash
cp hosts.ini.example hosts.ini
# hosts.ini에 실제 서버 정보를 채웁니다
```

`hosts.ini`는 `.gitignore`에 의해 추적되지 않습니다.

### 2. 실행 권한 부여

```bash
find . -name "*.sh" -exec chmod +x {} \;
```

---

## 🛡️ 민감 정보 관리 규칙

- `hosts.ini` — 실제 서버 IP/호스트명 포함. **절대 커밋 금지**
- SSH 키 — 저장소에 절대 포함 금지
- 비밀번호 / 토큰 — 스크립트에 하드코딩 금지

커밋 전 확인:

```bash
git diff --staged | grep -iE 'password|secret|token|[0-9]{1,3}\.[0-9]{1,3}\.[0-9]'
```
