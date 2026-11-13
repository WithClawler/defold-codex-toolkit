## Purpose

새 Defold stable 릴리즈를 감지하면 helper 호환 작업을 지속 가능한 큐로 전달하고, 중복 실행과 검증 없는 성공 보고를 막으면서 프로젝트 채널에서 후속 대화를 이어갈 수 있게 한다.

## ADDED Requirements

### Requirement: Durable release admission

시스템은 SHALL 릴리즈별 요청을 감지 상태보다 먼저 보존하며, 실행 가능한 프로젝트 채널에 하나의 작업 스레드와 하나의 primary 작업을 등록한다. 재시작·재감지·불확실한 등록 응답은 같은 식별자를 재사용한다.

#### Scenario: Repeated observation
- **WHEN** 같은 릴리즈를 반복 감지하거나 등록 응답을 잃고 재시도한다
- **THEN** 요청과 primary 작업이 중복 생성되지 않는다

#### Scenario: Explicit catch up
- **WHEN** 이미 감지했지만 요청이 없는 릴리즈를 catch-up으로 실행한다
- **THEN** 기존 감지 상태를 삭제하지 않고 그 릴리즈의 작업을 한 번 등록한다

### Requirement: Central policy and bounded execution

자동 작업은 SHALL 중앙 자동화 모델 정책을 상속하고 기존 작업 큐·worker·게시 경로를 사용한다. primary의 실행 오류 또는 결과 검증 실패에는 fallback을 한 번만 허용하며 취소·소유권 상실·유효한 차단 보고에는 새 호출을 만들지 않는다.

#### Scenario: Provider failure
- **WHEN** primary가 실행 오류로 종료한다
- **THEN** 같은 릴리즈 스레드에서 fallback을 최대 한 번 등록하고 기존 산출물을 보존한다

#### Scenario: User cancellation
- **WHEN** 작업이 취소되거나 사용자가 해당 자동 작업을 완료 처리한다
- **THEN** 자동 fallback이나 새 실행을 생성하지 않는다

### Requirement: Scoped verified compatibility

작업은 SHALL 기준 문서에 따라 helper 영향 분석·필요한 수정·대상 엔진 검증·호환 태그·결과 기록을 수행한다. 성공은 대상 버전의 검증 로그와 태그 근거가 확인되어야 하며 소비 게임은 별도 지정 없이 수정하지 않는다.

#### Scenario: Completed provider without evidence
- **WHEN** worker가 완료됐지만 대상 엔진 검증 근거가 없거나 태그가 일치하지 않는다
- **THEN** 호환 완료로 기록하지 않고 허용된 fallback 또는 실패 상태로 남긴다

### Requirement: Follow up in project thread

시스템은 SHALL 자동 작업의 진행·완료·차단 결과를 등록된 프로젝트 채널의 작업 스레드에 게시하고 사용자의 후속 요청을 같은 스레드에서 처리한다.

#### Scenario: Follow up after automation
- **WHEN** 사용자가 자동 작업 스레드에 후속 요청을 보낸다
- **THEN** 프로젝트 작업 binding과 기존 결과를 이어 사용한다
