# Stack Rush 공통화 점검

- 반영: Android AAB/APK의 모든 ELF debug section 검사와 ABI별 압축 용량 보고. Release strip/별도 심볼 보관 절차.
- 반영: localized_text의 primary 선준비 → fallback 연결 → fallback inventory 준비 순서, 동시 요청 합치기, 늦은 콜백 차단. fallback_text 옵션으로 소비자 글꼴 재고를 지정한다.
- 기존 공통 모듈 재사용 유지: gameplay_layer, score_records, settings_panel, localization_catalog. 프로젝트의 점수 단위 변환은 adapter다.
- 프로젝트 유지: prepared_settings_panel의 720×1280 로딩 UI와 5행 페이지 규칙, 광고 CHILD/G 설정과 앱 ID, 순위 서버, 일일 횟수, 개인정보 gate, 배경/블록/오디오 연출. 공통 모듈로 복사하면 소비자 정책이나 화면 구성을 강제하므로 옮기지 않는다.
- 글꼴 준비 코드는 기존 프로젝트 회귀 테스트와 helper 독립 테스트로 검증한다. 1.14.0 관련 우회는 엔진 변경 시 비교 검증 전까지 보존한다.
