# linux/

Linux 서버 모니터링 및 tmux 세션 자동 생성 관련 스크립트입니다.

---

## 📄 스크립트 목록

| 파일 | 설명 |
|------|------|
| `tmux.sh` | 운영용 tmux 세션 및 레이아웃 자동 생성 |

---

## 🚀 사용법

### 서버 모니터링

```bash
./linux/monitor.sh
```

`hosts.ini`에 등록된 서버에 SSH로 접속하여 아래 항목을 순서대로 출력합니다.

- CPU 사용률 (`top -bn1`)
- 메모리 사용량 (`free -h`)
- 디스크 사용률 (`df -h`)
- 최근 로그인 이력 (`last -n 5`)

---

### tmux 세션 자동 생성

```bash
./linux/tmux_session.sh [session_name]
```

세션 이름을 지정하지 않으면 기본값(`ops`)으로 생성합니다.  
이미 동일한 이름의 세션이 존재하면 해당 세션에 attach합니다.

**기본 레이아웃:**

```
┌──────────────┬──────────────┐
│   pane 0     │   pane 1     │
│  (메인 작업)  │  (로그 확인)  │
├──────────────┴──────────────┤
│            pane 2           │
│         (모니터링)           │
└─────────────────────────────┘
```

---

## 📋 hosts.ini 형식

```ini
[servers]
server1  ansible_host=<IP>  ansible_user=<USER>
server2  ansible_host=<IP>  ansible_user=<USER>

[controllers]
ctrl1    ansible_host=<IP>  ansible_user=<USER>

[computes]
compute1 ansible_host=<IP>  ansible_user=<USER>
compute2 ansible_host=<IP>  ansible_user=<USER>
```

그룹명은 스크립트 내 `TARGET_GROUP` 변수로 참조합니다.  
`hosts.ini.example`을 복사하여 사용하세요.
