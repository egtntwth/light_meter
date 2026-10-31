# light_meter

A light meter and shooting log for film cameras. Meter with your phone camera, log the exposure, location and time of every frame, then export the roll as JSON/CSV when it's finished. The exported file is meant for writing EXIF/GPS metadata into your scans later.

**Open the app:** https://egtntwth.github.io/light_meter/

It runs in the browser today on both Android and iPhone; each phone meters in the way it can, and the logging flow is the same on both. An iPhone app is planned for later.

## Why

A digital photo records its exposure, time and location as EXIF automatically. Film records none of it, so film shooters write everything down by hand, or don't. light_meter puts metering and note-taking in the same step: meter, press the shutter, and the frame is logged.

## Features

- **Roll setup**: pick a format (135, half-frame, 120 6×4.5 to 6×9, 110, 4×5, 8×10) and the frame count fills in automatically. Film, box ISO and EI (push/pull shown), auto-incrementing roll number, camera and lens, saved presets. Lab and scanner go in the roll memo.
- **Metering**: spot (tap), center-weighted or average metering; aperture or shutter priority; full-stop or 1/3-stop steps; highlight clipping warning.
- **Per-device metering method**: chosen by checking what the camera supports, not by OS name.
  - Android: real-time metering with locked exposure, where supported
  - iPhone/iPad: metering from the EXIF of a photo taken with the Camera app and picked from the library
  - Manual mode: log frames without metering
- **Exposure compensation and ISO**: ± EC and ISO changes right on the shooting screen.
- **Program shift**: drag the readout left or right to move along the same EV (f/4 1/500 = f/5.6 1/250 = f/8 1/125). Double-tap to reset.
- **Shot logging**: shutter → "Did you take the shot?" → confirm the values you actually used, saved with location and time. Skip it if you didn't shoot.
- **Frame counter**: shown as `1/36`, turns red past the roll's frame count.
- **Multiple exposure (ME)**: several exposures on one frame, planned count (2–6 or free), automatic −log₂ n EV compensation per exposure.
- **Location**: GPS recorded automatically. If it fails, the app explains why and lets you type in a place or coordinates.
- **End roll / export**: review and delete frames, export JSON (grouped by frame) or CSV, share from mobile.
- **Language**: English / 한국어

## How metering works

Scene brightness (EV₁₀₀) is computed as:

```
EV100 = log2(N² / t) − log2(ISO / 100) + log2(L / 0.18)
```

- `N`: the phone lens aperture; `t`, `ISO`: the shutter speed and ISO the phone camera actually used
- `L`: luminance of the metering area. Undo the sRGB gamma, then `0.2126R + 0.7152G + 0.0722B`, against an 18% middle gray

| Platform | Exposure data from the browser | Method |
|---|---|---|
| Android Chrome | Exposure time and ISO via `MediaStreamTrack` capabilities, manual exposure lock | Real-time absolute metering |
| iPhone Safari | Not provided | EXIF BrightnessValue (Bv) of a photo: `EV100 = Bv + 4`; spot adds relative brightness |

Recommended exposure: `t = N² / 2^(EV100 + log2(ISO/100))`, snapped to the nearest standard shutter speed or aperture, with the remaining error shown as ±EV.

**Why Bv on iPhone:** iPhone photos are HDR composites, so computing from the photo's pixels read about 2 stops bright. The EXIF BrightnessValue is not affected by the merge. The standard conversion (Bv + 5) still read 1.6 EV bright on average against a digital camera at dusk (f/8, ISO 400), so the offset was lowered to Bv + 4, bringing the average error to +0.6 EV. More indoor and shade samples are needed to refine it.

## Running it

Everything is in a single `index.html` with no server. Camera and location access only work over HTTPS, so use the GitHub Pages address.

Logs are stored in the browser (localStorage). They're lost if you clear browser data, so export each roll when it's done.

## Export format (JSON)

```json
{
  "schema": "light_meter/2",
  "roll": { "rollNo": 3, "format": "135", "frames": 36, "film": "Kodak Portra 400", "boxIso": 400, "ei": 400, "camera": "Nikon FM2", "lens": "50mm f/1.8" },
  "frames": [
    { "frame": 1, "multipleExposure": false, "exposureCount": 1,
      "exposures": [ { "exposure": 1, "time": "2026-10-30T14:02:11+09:00", "aperture": 8, "shutterLabel": "1/250",
                       "meteredEV100": 13.2, "lat": 37.4963, "lon": 126.9572 } ] }
  ]
}
```

## Repository

- `index.html`: the whole app (runs in the browser)
- `ios-app/`: an experimental Capacitor + Swift test project for a native iPhone app. Not built or tested on a device yet; the iPhone app is planned for later.

## Next steps

- A script that reads the exported JSON and writes EXIF/GPS into scan files with ExifTool, plus batch renaming of scans by roll and frame
- Wrap it as a Lightroom Classic plugin
- iPhone app: read the camera's shutter, ISO and aperture directly for real-time metering on iPhone too
- Android incident metering with the ambient light sensor
- More accuracy testing against a reference meter indoors and outdoors; cloud sync so exporting isn't needed

---

# light_meter (한국어)

필름 카메라용 노출계 + 촬영 기록장 앱입니다. 폰 카메라로 측광하고, 찍은 컷마다 노출값·위치·시각을 기록해 두었다가 롤이 끝나면 JSON/CSV로 내보냅니다. 내보낸 파일은 나중에 스캔본에 EXIF/GPS 메타데이터를 입히는 데 씁니다.

**바로 열기:** https://egtntwth.github.io/light_meter/

지금은 웹으로 안드로이드와 아이폰에서 동작합니다. 측광 방식은 기기마다 다르지만 기록은 같은 흐름으로 남습니다. 아이폰 앱은 추후 추가할 예정입니다.

## 만든 이유

디지털 사진은 노출·시각·위치가 EXIF로 자동으로 남지만, 필름은 아무것도 남지 않아 손으로 적어야 합니다. light_meter는 측광과 기록을 한 동작으로 묶었습니다. 측광하고 셔터를 누르면 그 컷이 기록됩니다.

## 기능

- **롤 설정**: 포맷(135, 하프프레임, 120 6×4.5~6×9, 110, 4×5, 8×10)을 고르면 컷 수 자동 입력, 필름·박스 ISO·EI(푸시/풀 표시), 롤 번호 자동 증가, 카메라·렌즈, 프리셋 저장. 현상소·스캐너는 롤 메모에 적습니다.
- **측광**: 터치 스팟 / 중앙중점 / 평균 측광, 조리개 우선·셔터 우선, 1스톱·1/3스톱 단계, 하이라이트 포화 경고
- **기기별 측광 방식**: OS 이름이 아니라 카메라가 지원하는 기능을 확인해서 선택
  - 안드로이드: 실시간 측광(지원 기기는 노출 고정)
  - 아이폰·아이패드: 기본 카메라 앱으로 찍은 사진을 앨범에서 골라 EXIF로 측광
  - 수동 모드: 측광 없이 기록만
- **노출 보정·ISO 변경**: 촬영 화면에서 바로 ± 보정과 ISO 변경
- **프로그램 시프트**: 리드아웃을 좌우로 드래그하면 같은 EV에서 조리개·셔터 조합만 변경(f/4 1/500 = f/5.6 1/250 = f/8 1/125), 두 번 탭하면 초기화
- **촬영 기록**: 셔터 → "사진 찍었나요?" → 실제 사용값 확인 후 위치·시각과 함께 저장, 안 찍었으면 건너뛰기
- **컷 카운터**: `1/36` 형식, 정해진 컷 수를 넘으면 빨간색 경고
- **다중노출(ME)**: 같은 컷에 여러 노출 기록, 횟수 계획(2~6회/자유), 노출당 자동 보정(−log₂ n EV)
- **위치**: GPS 자동 기록, 실패 시 원인 안내와 장소·좌표 직접 입력
- **롤 종료 / 내보내기**: 컷 목록 확인·삭제, JSON(컷 단위로 묶음)·CSV 내보내기, 모바일 공유
- **언어**: 한국어 / English

## 측광 원리

장면의 밝기(EV₁₀₀)는 다음과 같이 계산합니다.

```
EV100 = log2(N² / t) − log2(ISO / 100) + log2(L / 0.18)
```

- `N`: 폰 렌즈 조리개, `t`, `ISO`: 폰 카메라가 실제로 쓴 셔터와 감도
- `L`: 측광 영역 휘도. sRGB 감마를 풀고 `0.2126R + 0.7152G + 0.0722B`로 계산, 18% 중간회색 기준

| 플랫폼 | 브라우저가 주는 노출 정보 | 방식 |
|---|---|---|
| Android Chrome | `MediaStreamTrack`으로 노출시간·ISO 제공, 노출 고정 가능 | 실시간 절대 측광 |
| iPhone Safari | 제공하지 않음 | 사진 EXIF 밝기값(Bv): `EV100 = Bv + 4`, 스팟은 상대 밝기 추가 |

추천 노출: `t = N² / 2^(EV100 + log2(ISO/100))`를 가장 가까운 표준 셔터/조리개 값으로 맞추고, 남는 오차는 ±EV로 표시합니다.

**아이폰에서 Bv를 쓰는 이유:** 아이폰 사진은 HDR 합성이라 사진 픽셀로 계산하면 약 2스톱 밝게 나왔습니다. EXIF 밝기값(Bv)은 합성의 영향을 받지 않습니다. 표준 변환식(Bv + 5)도 해 질 녘 디지털카메라(f/8, ISO 400)와 비교하면 평균 1.6 EV 밝게 나와서 Bv + 4로 낮췄고, 평균 오차는 +0.6 EV가 됐습니다. 실내·그늘 표본을 더 모아 다듬을 예정입니다.

## 실행

서버 없이 `index.html` 하나로 동작합니다. 카메라와 위치 권한은 HTTPS에서만 열리므로 GitHub Pages 주소로 접속하세요.

기록은 브라우저 저장소(localStorage)에 저장됩니다. 브라우저 데이터를 지우면 사라지니 롤이 끝나면 내보내기를 해 두세요.

## 내보내기 형식

JSON 예시는 위 영어 섹션의 "Export format"을 참고하세요. CSV는 노출 한 번이 한 줄입니다.

## 저장소 구성

- `index.html`: 앱 전체 (브라우저에서 실행)
- `ios-app/`: Capacitor + Swift로 만든 아이폰 앱 테스트 프로젝트. 아직 실기기 빌드 전이며, 아이폰 앱은 추후 추가할 예정입니다.

## 다음 단계

- 내보낸 JSON을 읽어 ExifTool로 스캔 파일에 EXIF·GPS를 일괄 기록하는 스크립트, 롤·컷 번호로 스캔 파일 일괄 이름 변경
- Lightroom Classic 플러그인으로 감싸기
- 아이폰 앱: 카메라의 셔터·ISO·조리개를 직접 읽어 아이폰에서도 실시간 측광
- 안드로이드 조도 센서로 입사식 측광
- 실내·실외에서 기준 노출계 대비 정확도 검증, 클라우드 동기화로 내보내기 없이
