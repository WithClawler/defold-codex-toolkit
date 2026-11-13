# Design

## Context

Python 감지기는 launchd에서 실행되고 `_ops`는 durable dispatcher와 Slack adapter를 이미 운영한다. 모델 기본값은 `_ops/app/services/agents/automation-model-policy.ts`이며 짧은 분류용 no-tools router와 실제 코딩 worker를 구분한다.

## Goals / Non-Goals

**Goals:** 릴리즈 요청을 먼저 저장하고 기존 daemon이 프로젝트 작업으로 접수한다. restart와 오류 뒤 동일 식별자로 복구한다. 등록된 프로젝트 작업과 source WIP를 보존한다.

**Non-Goals:** 소비 게임 일괄 업그레이드, 별도 사용자-token 메시지, 별도 AI 세션 실행기와 모델 설정, 출시·스토어 배포.

## Decisions

- 감지기는 `.local/engine-release-jobs/<version>/request.json`을 원자적으로 생성한다. 새 자동화 모드에서는 Slack 직접 발송 대신 이 outbox를 사용한다. 기존 standalone 알림 모드는 호환 옵션으로 유지한다.
- `_ops`의 명시적 opt-in 설정은 project slug와 요청 소유자를 지정한다. 실제 경로와 채널은 active project registry에서 얻는다. gateway 활성화 후 watcher가 outbox를 읽고 공유 Slack client로 root를 생성한 뒤 dispatcher에 등록한다.
- root 게시 전 durable claim을 기록하고 Slack metadata로 readback한다. 응답이 불확실하면 확인 전 재게시하지 않는다. 작업 등록은 root ID 및 attempt로 중복을 억제한다.
- 중앙 정책을 primary/fallback 작업에 적용한다. 일반 worker가 도구를 사용할 수 있게 하되 자동 quota 재개와 일반 auto-recovery는 이 작업에서 제한해 fallback 중복을 막는다. 사용자 작업과 자동 작업이 같은 workspace를 동시에 수정하지 않도록 접수 시 진행 작업을 확인한다.
- 작업 프롬프트는 저장소·기준 문서·릴리즈 요청 디렉터리만 전달한다. 기준 문서가 수정·검증·commit/push·태그·result.json 완료 조건을 소유한다. 외부 release body는 실행 명령이 아닌 데이터다.
- 완료 artifact는 engine version/SHA, helper commit/tag, 실제 테스트 로그를 포함한다. daemon이 결과 파일과 git tag·engine marker를 확인한다. 유효한 blocked 결과는 fallback을 유발하지 않는다.

## Risks / Trade-offs

- Slack 게시 성공 직후 응답/프로세스 유실 → metadata 재조회로 복구하고 근거 없는 재발송은 보류한다.
- 첫 worker가 일부 수정 후 실패 → fallback은 현재 파일과 기존 결과를 읽고 이어가며 reset/stash/tag 덮어쓰기를 금지한다.
- parent 구현 작업과 자동 검증 충돌 → 배포·commit 이후 현재 릴리즈를 catch-up하고 admission 대기 상태를 확인한다.

## Migration Plan

양쪽 저장소의 요청 변경을 검증·commit/push하고 `_ops` 표준 immutable release를 배포한다. opt-in config와 launcher 자동화 모드를 적용한 뒤 1.14.1을 catch-up한다. rollback은 opt-in을 끄고 저장한 launchd 설정을 복원하며 요청·작업·결과 원장은 삭제하지 않는다.
