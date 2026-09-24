# BlowerFit KR

**풍량·풍압·개구부·에어나이프·배관망·진공 조건을 계산하고, 실제 블로워 카탈로그 데이터와 한국 공급처를 연결하는 산업용 블로워 선정 웹서비스**입니다.

현재 버전은 GitHub Pages에서 바로 배포 가능한 **정적·로컬 우선(local-first) 엔지니어링 도구**입니다. 서버나 API Key가 없어도 계산·검색·리포트 저장/내보내기가 작동합니다.

> **중요:** 카탈로그의 최대풍량과 최대풍압은 일반적으로 같은 운전점이 아닙니다. BlowerFit KR은 이를 하나의 동시 성능점으로 취급하지 않으며, 최종 발주 전 제조사 공식 P-Q 곡선/duty sheet 검증을 요구합니다.

## Preview

첫 화면에서 7가지 선정 기준 중 하나를 선택할 수 있습니다.

1. 풍량 기준
2. 풍압 기준
3. 개구부/타공 기준 — 원형·사각·슬롯·장홀
4. 에어나이프/액절단 기준
5. 주배관 + 개별 가지관 네트워크
6. 진공/흡입 기준
7. 사용처별 빠른 선정

계산 후에는 설계 풍량·압력, 환경 보정, 배관 압력손실, 주/가지관 권장 규격, 예비 모터 동력, 실제 DB 후보, 구매처, 계산식과 대입값이 함께 표시됩니다.

## Features

- **계산식 공개:** 공식 → 실제 대입값 → 결과를 화면과 보고서에 표시
- **환경 보정:** 온도·고도·상대습도를 이용한 습공기 밀도 계산
- **개구부 계산:** 원형/사각/슬롯/장홀 면적 × 수량 × 목표 제트속도
- **에어나이프 계산:** 폭·슬롯 간극·개수·제트속도·라인속도·블로우존 체류시간
- **배관망 계산:** 가지관별 유량·길이·말단압력·엘보·T·기타 K 입력
- **배관 사이징:** 목표 유속 기반 이론 내경 + 표준 내경 상향 선택
- **압력손실:** Darcy–Weisbach + Swamee–Jain + 국부손실 계수 K
- **진공 모드:** 흡착면적·하중·안전율·누설 여유로 진공 Duty 계산
- **제품 DB:** 초기 80개 사양 variant, 22개 제조사/브랜드 메타데이터
- **구매처 DB:** 제조사 직판/공식 한국법인/공식 문의채널 분리
- **후보 품질 표시:** endpoint 통과와 P-Q 검증 상태 분리
- **제품 검색/필터/즐겨찾기/최대 4개 비교**
- **리포트:** PDF, PNG, HTML, JSON, 브라우저 인쇄
- **브라우저 저장:** LocalStorage에 최근 프로젝트와 최대 50개 리포트 보관
- **공유:** 입력조건을 URL state로 인코딩해 링크 공유
- **반응형/다크모드/PWA:** 모바일·태블릿·데스크톱, 시스템 테마, 오프라인 캐시
- **GitHub Pages:** 상대 경로 + Hash routing + GitHub Actions 자동 배포
- **Windows 원클릭 배포:** `github-bootstrap.cmd`

## Engineering Model

### 습공기 밀도

```text
ρ = Pd / (Rd·T) + Pv / (Rv·T)
```

표준대기압은 설치 고도로 보정하고, 포화수증기압과 상대습도를 사용해 건공기/수증기 분압을 나눕니다.

### 배관 압력손실

```text
ΔP = f · (L/D) · ρv²/2 + ΣK · ρv²/2
```

- 난류: Swamee–Jain 근사식
- 층류: `f = 64 / Re`
- 기본 예비 K: 90° 엘보 `0.75`, T `1.5`
- 실제 제작 시 밸브/Reducer/Expander/유연조인트/필터/소음기 제조사 손실을 추가해야 합니다.

### 개구부 / 에어나이프

```text
Q = A · v
ΔP ≈ ρ/2 · (v/Cd)²
```

이는 **저~중차압 예비식**입니다. 고속 제트, 고차압, 매우 작은 슬롯에서는 압축성 유동, 노즐 형상, 균압 헤더 및 실험/CFD 검증이 필요합니다.

### 모터 예비값

```text
Pair = Q · ΔP
Pmotor ≈ Pair / η × 1.10
```

현재 `η = 0.58`을 예비 가정으로 사용합니다. 실제 축동력/패키지 입력전력은 제조사 성능표를 우선합니다.

### 모델 선정 로직

1. 계산된 설계 Duty로 endpoint pre-filter
   - `Qmax ≥ Qdesign`
   - `Pmax ≥ Pdesign` 또는 진공모드 `Vacuummax ≥ Vacuumdesign`
2. 50/60 Hz 조건 확인
3. 용도 태그·한국 조달경로·출력 여유 등을 후보점수에 반영
4. 공식 P-Q 데이터가 없으면 **`P-Q 검증 필요`** 유지
5. 최종 발주 전 `Q(Pdesign) ≥ Qdesign`을 공식 곡선/duty sheet로 확인

## Tech Stack

의존성 수를 최소화하고 GitHub Pages에서 안정적으로 동작하도록 구성했습니다.

- HTML5 / CSS3
- JavaScript ES Modules
- Static JSON database
- LocalStorage
- Hash routing
- Native Canvas report renderer
- 경량 직접 PDF writer — 이미지 기반 A4 보고서
- Service Worker / Web App Manifest
- Node.js built-in build/test/dev scripts
- Node `--test`
- GitHub Actions + GitHub Pages

**프런트엔드 런타임 의존성은 0개**입니다.

## Project Structure

```text
blowerfit-kr/
├─ web/
│  ├─ index.html
│  ├─ app.js
│  ├─ calculations.js
│  ├─ selection.js
│  ├─ styles.css
│  ├─ data/
│  │  ├─ blower_webservice_seed.json
│  │  └─ search_taxonomy.json
│  ├─ favicon.svg / favicon.ico / favicon PNGs
│  ├─ apple-touch-icon.png
│  ├─ icon-192.png / icon-512.png
│  ├─ og-image.png
│  ├─ repo-social-preview.png
│  ├─ manifest.webmanifest
│  ├─ sw.js
│  ├─ robots.txt / sitemap.xml
│  ├─ 404.html
│  └─ .nojekyll
├─ scripts/
│  ├─ dev-server.mjs
│  └─ build.mjs
├─ tests/
│  ├─ calculations.test.mjs
│  ├─ selection.test.mjs
│  └─ project.test.mjs
├─ .github/workflows/deploy.yml
├─ github-bootstrap.cmd
├─ package.json
├─ package-lock.json
├─ README.md
├─ LICENSE
└─ .gitignore
```

## Local Development

Node.js 20+ 권장, 22 LTS 권장.

```bash
npm install
npm run dev
```

기본 주소:

```text
http://localhost:5173/
```

## Test

```bash
npm test
```

계산식의 기본 물리 일관성, 데이터 seed, 선정 후보 생성, 필수 배포자산을 검사합니다.

## Build

```bash
npm run build
```

결과는 `dist/`에 생성됩니다. 운영 URL을 메타데이터/robots/sitemap에 반영하려면:

### Windows PowerShell

```powershell
$env:VITE_SITE_URL='https://USERNAME.github.io/REPOSITORY/'
npm run build
```

### Bash

```bash
VITE_SITE_URL='https://USERNAME.github.io/REPOSITORY/' npm run build
```


## Windows 실행 / 배포 (v1.0.1 수정)

### 먼저 웹서비스만 확인하기

Git이나 GitHub 계정 없이도 `PREVIEW_WINDOWS.cmd`를 더블클릭하면 로컬 미리보기를 실행할 수 있습니다. Node.js가 있으면 내장 개발서버를 사용하고, 없으면 Python 또는 Windows PowerShell 기반 정적 서버로 자동 폴백합니다.

### GitHub Pages에 배포하기

`DEPLOY_WINDOWS.cmd` 또는 `github-bootstrap.cmd`를 실행하세요. v1.0.1부터 두 CMD 파일은 **ASCII + CRLF**로 저장되어 한국어 Windows CMD의 UTF-8 깨짐 문제를 피합니다. Git 또는 GitHub CLI가 없으면 `winget`을 이용한 설치 여부를 먼저 묻습니다. Node.js가 로컬에 없어도 배포는 가능하며, GitHub Actions가 Node 22 환경에서 테스트와 빌드를 수행합니다.

이전 v1.0.0의 `github-bootstrap.cmd`에서 `곕씪`, `NITIAL_TAG` 같은 깨진 명령이 보였다면 파일 인코딩/줄바꿈 호환 문제입니다. v1.0.1의 배치 파일로 교체하세요. 마지막에 `[ERROR] Git not found`가 나온 경우는 별개의 실제 환경 문제로, Git이 설치되어 있지 않거나 PATH에 잡혀 있지 않다는 의미입니다.

## GitHub Pages Deployment

### 방법 A — Windows 원클릭 Bootstrap

프로젝트 루트에서:

```text
github-bootstrap.cmd
```

스크립트가 다음을 순서대로 처리합니다.

`Git/Node/npm/gh 확인 → GitHub 로그인 → Git identity → npm install → test/build → Repository 생성/재사용 → commit/push → Description/Homepage/Topics → Pages 활성화 → Actions 배포 감시 → v1.0.0 tag/release`

완료된 단계가 이미 있으면 중복 생성하지 않고 재사용합니다. PAT, 비밀번호, Secret은 코드에 저장하지 않습니다.

### 방법 B — 수동

```bash
git init
git branch -M main
git add .
git commit -m "feat: launch BlowerFit KR engineering selector"
git remote add origin https://github.com/USERNAME/blowerfit-kr.git
git push -u origin main
```

GitHub에서 `Settings → Pages → Source → GitHub Actions`를 선택합니다. 이후 `main` push마다 `.github/workflows/deploy.yml`이 test/build 후 Pages를 갱신합니다.

## Configuration

- `web/index.html` — title, SEO, OG/Twitter, JSON-LD
- `web/data/blower_webservice_seed.json` — 제조사/모델/variant/한국 공급처
- `web/data/search_taxonomy.json` — 동의어·단위·검색 facet
- `web/calculations.js` — 유체/배관/개구부/진공 계산
- `web/selection.js` — 모델 후보 및 DB 필터
- `VITE_SITE_URL` — 빌드 시 canonical/OG/robots/sitemap URL

## Data Update Policy

1. 공식 최신 카탈로그
2. 공식 최신 웹
3. 공식 구버전
4. 사용자가 제공한 제조사 카탈로그
5. 공식 대리점/유통사
6. 검증 가능한 2차 자료

순으로 신뢰도를 관리합니다.

- 확인되지 않은 수치는 임의 추정하지 않습니다.
- 50/60 Hz가 다르면 별도 variant로 관리합니다.
- 구형 제품은 현행 제품과 분리합니다.
- 가격·납기가 공개 검증되지 않으면 RFQ 방식으로 유지합니다.
- 성능곡선에서만 판정 가능한 값은 `curve_required` 상태를 유지합니다.

## GitHub Pages 하위경로 대응

모든 정적 자산은 상대경로(`./`)를 사용하고 내부 페이지는 Hash route를 사용합니다.

```text
https://USERNAME.github.io/REPOSITORY/#/selector
https://USERNAME.github.io/REPOSITORY/#/products
```

따라서 저장소 이름이 루트가 아닌 GitHub Pages에서도 새로고침/직접 접근 문제가 적습니다.

## Custom Domain

GitHub Pages `Settings → Pages → Custom domain`에서 연결합니다. 도메인을 Repository로 함께 관리하려면 빌드 소스인 `web/CNAME`에 도메인 한 줄을 추가합니다.

```text
blower.example.com
```

DNS 반영 후 **Enforce HTTPS**를 활성화하고 `VITE_SITE_URL`도 커스텀 도메인으로 바꿉니다.

## PWA / Offline

설치형 UI가 필요한 사용자를 위해 Web App Manifest와 Service Worker를 포함합니다. 최초 온라인 로드 후 사용된 정적자산/데이터를 캐시해 재방문 안정성을 높입니다. 블로워 원본 데이터는 공개 정적 JSON이므로 민감정보를 넣지 않습니다.

## Security

GitHub Pages는 공개 프런트엔드입니다.

소스나 정적 JSON에 다음을 넣지 마세요.

- API Key / PAT / Private Key
- 비밀번호
- 공급사 비공개 원가/단가
- 개인정보/민감정보

향후 실제 RFQ 자동 전송, 로그인, 비공개 가격 또는 주문 처리가 필요하면 별도 Serverless API/Backend와 Secret 저장소를 분리해야 합니다.

## Engineering Responsibility / Limitations

BlowerFit KR은 **예비 선정과 설계 비교 속도를 높이는 엔지니어링 보조도구**이며 제조사 성능보증서, 인증 계산서 또는 최종 배관설계서를 대체하지 않습니다.

최종 발주 전 반드시 확인할 항목:

- 공식 P-Q 운전점
- 압축성 영향이 큰 고속/고차압 노즐
- 복잡한 분기관 밸런싱
- 부식성/습윤/염분/미스트 포함 가스
- 설치 온도·고도에 따른 모터 및 냉각 derating
- 흡입필터/소음기/체크밸브 실제 손실
- 모터 전압·전류·인버터 허용범위
- 소음/방폭/안전밸브/현장 전기규격
- 보증·A/S·예비품·납기

## Repository Metadata Recommendation

- Repository: `blowerfit-kr`
- Description: `산업용 블로워 선정·배관 사이징·모델/구매처 연결 엔지니어링 웹서비스`
- Topics: `blower`, `engineering`, `air-knife`, `ring-blower`, `turbo-blower`, `github-pages`, `javascript`, `pwa`
- Initial tag: `v1.0.0`
- Initial commit: `feat: launch BlowerFit KR engineering selector`

## Social Preview

- 웹 OG 이미지: `web/og-image.png` — 1200×630
- GitHub Repository Social Preview: `web/repo-social-preview.png` — 1280×640

Repository의 `Settings → General → Social preview`에서 `repo-social-preview.png`를 업로드하면 됩니다.

## License

MIT License.

단, 포함된 제조사명/상표/카탈로그 사양의 권리는 각 권리자에게 있으며, 공개 배포 시 원 출처의 재사용 조건을 별도로 확인해야 합니다.

## v1.0.2 Windows deployment fix

Windows에서 `npm run build` 실행 시 `C:\\C:\\...\\dist` 형태의 잘못된 경로가 생성되던 문제를 수정했습니다. 원인은 ES module URL의 `.pathname`을 Windows 경로로 직접 사용한 것이며, v1.0.2부터 `fileURLToPath(import.meta.url)`을 사용합니다.

배포는 프로젝트 루트에서 `github-bootstrap.cmd` 또는 `DEPLOY_WINDOWS.cmd`를 실행하세요. 로컬 검증이 먼저 통과한 뒤 Git 저장소 생성/commit/push 및 GitHub Pages workflow 배포를 진행합니다.
