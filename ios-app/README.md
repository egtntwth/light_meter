# light_meter iOS 앱 (테스트용)

웹앱(`../index.html`)을 그대로 아이폰 앱으로 감싸고, 카메라가 실제로 쓰는 셔터·ISO·조리개를 읽는 Swift 플러그인을 붙인 프로젝트입니다. 웹에서는 막혀 있던 **아이폰 실시간 절대 측광**이 됩니다.

- 웹앱 코드는 하나입니다. 앱 안에서 실행되면 측광 방식이 자동으로 **앱**으로 바뀌고, 브라우저에서는 지금처럼 동작합니다.
- 측광: 아이폰 자동노출이 측광점(스팟은 탭한 곳, 중앙중점·평균은 가운데)에 맞춘 노출값과 목표와의 차이로 계산합니다.
  `EV100 = log2(N²/t) − log2(ISO/100) + exposureTargetOffset`
- 플러그인 코드: `native/LightMeterPlugin.swift`

## 준비물

- 맥 + **Xcode** (App Store에서 무료 설치, 처음 실행할 때 추가 구성요소 설치)
- **Node.js** LTS (nodejs.org)
- 아이폰 + USB 케이블
- Apple ID (무료 계정으로 충분)

## 처음 한 번

터미널에서:

```bash
git clone https://github.com/egtntwth/light_meter.git
cd light_meter/ios-app
npm install
npm run setup     # Xcode 프로젝트 생성 + 플러그인·권한 자동 연결
npm run open      # Xcode 열기
```

Xcode에서:

1. 왼쪽에서 **App** 프로젝트 → TARGETS **App** → **Signing & Capabilities**
2. **Team**: Xcode → Settings → Accounts에 Apple ID를 추가한 뒤 `(Personal Team)` 선택
3. **Bundle Identifier**가 이미 쓰인다는 오류가 나면 끝에 아무 글자나 붙이기 (예: `io.github.egtntwth.lightmeter.minseo`)

아이폰에서:

1. USB로 맥에 연결 → "이 컴퓨터를 신뢰" 선택
2. 설정 → 개인정보 보호 및 보안 → **개발자 모드** 켜기 (재시동)
3. Xcode 위쪽 기기 목록에서 내 아이폰을 고르고 **▶ (Run)**
4. "신뢰할 수 없는 개발자"가 뜨면: 설정 → 일반 → VPN 및 기기 관리 → 내 Apple ID → 신뢰

## 웹앱을 고친 뒤

```bash
cd light_meter/ios-app
git pull
npm run sync      # 새 index.html 복사 + 플러그인 다시 연결
```

그다음 Xcode에서 다시 ▶.

## 알아 둘 것

- 무료 Apple ID로 설치한 앱은 **7일 뒤 실행이 안 됩니다.** 다시 ▶ 하면 7일 연장됩니다. 친구에게 배포하려면 유료 개발자 계정(연 $99)과 TestFlight가 필요합니다.
- 사진 측광의 EXIF 도구(exifr)는 인터넷에서 받아오므로, 사진 모드는 인터넷이 연결돼 있어야 합니다.
- 이 Swift 코드는 맥 없이 작성해서 아직 빌드해 보지 않았습니다. Xcode에서 빨간 오류가 나면 오류 문구를 그대로 복사해 알려 주세요.

## 직접 바꾸기 (스크립트가 실패했을 때만)

- `ios/App/App/Base.lproj/Main.storyboard`를 열어 첫 화면(Bridge View Controller)의 Identity Inspector에서 Class를 `MainViewController`, Module을 `App`으로
- `ios/App/App/Info.plist`에 `NSCameraUsageDescription`, `NSLocationWhenInUseUsageDescription` 추가
