# 엔진 릴리즈 자동화 운영 검증 — 2026-11-13

릴리즈 감지부터 helper 검증·호환 태그 push·프로젝트 채널 보고까지 실제로 실행했다.

## 배포와 실행

- 감지기/작업 계약: `24b469d`, `_ops` runtime: `9ebe189e`.
- 운영 release: `20261113T140848Z-9ebe189e-16505`. clean export를 빌드하고 표준 `install-launchd.sh`로 설치했다. DB online backup의 integrity check가 통과했고, 배포 전 실행 중 작업들의 release pin은 유지됐다.
- engine launchd: `OpsMacAutomationRunner` 사용, 금요일 09:15 유지, `DEFOLD_ENGINE_RELEASE_AUTOMATION=1`. audit에서 두 Defold 예약 작업 모두 runner 사용과 TCC 오류 없음을 확인했다.
- `1.14.1` catch-up 요청을 저장한 뒤 daemon의 `waiting_for_project`를 확인했다. 구현 요청의 편집·commit/push가 끝난 뒤 해당 요청 하나만 읽기 전용 관찰자로 제외한 일회성 검증으로 같은 서비스·lock·durable dispatcher를 호출했다. 다른 작업 대기 조건과 운영 callback, task 상태·lease는 변경하지 않았다. 관찰 프로세스는 검증 완료 후 종료했다.
- 실제 task `12616`: `antigravity-cli`, `gemini-4-hydrogen-low`, `low`, 위 운영 release에 고정. 중앙 fallback은 `gpt-6-luna / low`이며 이번 성공 실행에는 호출되지 않았다.
- [프로젝트 작업 스레드](https://mibcompany.slack.com/archives/C0AQVKUJTV3/p1794579020277289): root와 실행 모델, 최종 답변 `1794579126.087469`, JSON 첨부 `F0CHHH20AJE`, root의 `호환 검증 완료` 상태를 Slack 재조회로 확인했다. 일반 project thread binding이 생성됐다. 실제 사용자의 후속 메시지 입력은 별도 실행하지 않았다.

## 검증 결과

- Lua suite 통과, Python 15개 통과, Defold 1.14.0 회귀 smoke와 대상 1.14.1 headless smoke 통과.
- 1.14.1 marker: `DEFOLD_HELPER_ENGINE_SMOKE_OK 1.14.1 ee283d4dad9fa451dd6399d83602e1dc25133681`.
- Bob SHA-256을 로컬 파일에서 다시 계산해 `f47e0d21fee84c3c1f56adfe5feb1c328f83df9e4fe26f2616a5392b9b710b45`와 일치함을 확인했다.
- `defold-1.14.1`의 로컬/원격 commit은 `c6b46bf0acfa41702a9c2013d72ddee3fbbe6a0a`. worker 완료 뒤 runtime이 로그·tag를 검사해 원장을 `verified`로 바꿨다.
- `_ops` clean build와 관련 82개 검사(자동화 16, 모델 정책 5, 복구 18, daemon 43)가 통과했다. 앞선 worker/project 통합 회귀 179개도 통과했다.
- 더 넓게 실행된 검사에서 기존 Discord prompt의 `memoryContext` 기대값 두 건이 실패했다. 변경 전 `f398f52c`에서도 같은 두 실패를 재현했으며 이번 요청에서 수정하지 않았다.
- 자동 보고 본문에 provider의 가상 드라이브 `localhost` 링크가 남은 것을 확인했다. JSON 파일의 실제 업로드와 답변 게시는 성공했다. 후속 작업 계약에는 원래 저장소 경로만 링크로 사용하도록 보강했다. 이 안내의 이후 provider 출력 준수는 아직 별도 실행하지 않았다.

실행 로그와 receipt는 ignored 경로 `.local/verification/engine-notification-20261113/`와
`.local/engine-release-jobs/1.14.1/`에 보존한다. 호환 범위와 소비 게임의 미검증 사항은
[engine-compatibility.md](engine-compatibility.md)에 기록했다. 소비 게임 수정·빌드·배포는 수행하지 않았다.

## 중지와 복구

신규 자동 접수는 보호된 runtime `state/defold-helper-automation/config.json`의 `enabled=false`로 중지한다.
진행 작업은 해당 스레드의 표준 `--stop`을 사용한다. 요청·결과·작업 원장은 삭제하지 않는다.
운영 backup은 `com.works.ops/backups/defold-helper-release-20261113T140739Z`에 있다.
