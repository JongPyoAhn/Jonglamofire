# Jonglamofire 0.1 Migration Guide
Jonglamofire는 인기있는 네트워킹 라이브러리인 Alamofire의 내부 구조와 동작방식을 공부하기위한 라이브러리 프로젝트입니다.
그저 라이브러리만 가져다가 조립할 줄만 안다면, 현업에서 여러가지 업데이트로 인한 에러나 라이브러리에 에러가 발생하는 상황이 생긴다면 고치는데 시간이 오래걸리거나 고칠 수 없을지도 모른다고 생각해서 해당 프로젝트를 시작하게 되었습니다.

## 변경사항
- **0.1.0:** 라이브러리 생성
- **0.1.1:** 라이브러리 시험
- **0.1.2:** 제한된 기능의 `request(_:)` 함수 분석 및 구현
- **0.1.3:** `resume()` 함수 분석 및 구현 & `MutableState` 분석 및 구현 & `Protected` 분석 및 구현
- **0.1.4:** `response()` 함수 분석 및 구현 & `SessionDelegate` 분석 및 구현 & `RequestTaskMap` 을 통한 Request와 Task 매핑
