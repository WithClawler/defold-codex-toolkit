# engine-compatibility Specification

## Purpose
소비 프로젝트를 업그레이드하기 전에 고정된 Defold 엔진에서 공용 helper를 실제 실행하여, 정적 검사와 엔진 호환 검증의 차이를 확인하고 재현할 수 있게 한다.

## Requirements

### Requirement: Reproducible engine smoke

호환 검사는 SHALL 현재 helper source를 격리된 project로 복사하고 지정된 Bob의 버전을 확인한 뒤 실제 Defold 엔진에서 helper API를 실행한다. 기존 소비 프로젝트나 공유 엔진 파일을 변경해서는 안 된다.

#### Scenario: Successful compatibility check

- **WHEN** 지원 버전의 Bob을 지정하여 검사를 실행한다
- **THEN** helper 모듈 로딩, GUI와 설정 처리가 실제 엔진에서 성공하고 명시적인 통과 marker를 반환한다

#### Scenario: Failed or interrupted runtime

- **WHEN** 엔진이 오류를 내거나 제한 시간 안에 통과 marker를 반환하지 않는다
- **THEN** 검사는 nonzero로 종료하고 성공으로 기록하지 않는다

### Requirement: Scoped compatibility evidence

호환 기록은 SHALL 공식 엔진 버전과 SHA, helper source 식별자, 수행한 검사와 미검증 플랫폼을 구분한다. 엔진 smoke 통과를 소비 게임 전체 QA나 스토어 배포 완료로 표현해서는 안 된다.

#### Scenario: Release evidence

- **WHEN** 특정 엔진용 helper 호환 tag를 발행한다
- **THEN** 호환 문서에서 실제 검사 결과와 소비 프로젝트 적용 범위를 확인할 수 있다
