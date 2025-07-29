# 개발 워크플로우

## Git 브랜치 전략

### 1. 브랜치 구조
```
main (프로덕션)
├── develop (개발 통합)
│   ├── feature/BE/{작업명}
│   ├── feature/IF/{작업명}
│   └── feature/FE/{작업명}
```

### 3. 커밋 메시지 규칙
- 반드시 한국어로 작성할 것

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**타입 종류:**
- `feat`: 새로운 기능 추가
- `fix`: 버그 수정
- `docs`: 문서 수정
- `style`: 코드 포맷팅, 세미콜론 누락 등
- `refactor`: 코드 리팩토링
- `test`: 테스트 코드 추가/수정
- `chore`: 빌드 과정, 보조 도구 수정

**예시:**
```
feat: Config Server ReplicaSet 구성 자동화 terraform파일 추가

```
