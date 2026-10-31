// `npx cap add ios`가 만든 Xcode 프로젝트에 light_meter 네이티브 부분을 붙인다.
// 여러 번 실행해도 같은 결과가 되도록 이미 붙어 있으면 건너뛴다.
//  1) Swift 플러그인 코드를 AppDelegate.swift 끝에 붙인다 (이미 빌드 대상인 파일이라 Xcode에서 파일을 추가할 필요가 없다)
//  2) Main.storyboard의 첫 화면을 플러그인을 등록하는 MainViewController로 바꾼다
//  3) Info.plist에 카메라·위치 권한 문구를 넣는다
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const appDir = join(here, '..', 'ios', 'App', 'App');
if (!existsSync(appDir)) {
  console.error('ios/App/App 폴더가 없어요. 먼저 `npm run setup`을 실행하세요.');
  process.exit(1);
}

// 1) Swift 플러그인
const MARK = '// --- light_meter native plugin ---';
const delegatePath = join(appDir, 'AppDelegate.swift');
let delegate = readFileSync(delegatePath, 'utf8');
const pluginSrc = readFileSync(join(here, '..', 'native', 'LightMeterPlugin.swift'), 'utf8');
// import 줄은 파일 맨 위로 옮기고, 나머지 코드는 끝에 붙인다
const imports = pluginSrc.split('\n').filter(l => /^import\s+\w+/.test(l));
const plugin = pluginSrc.split('\n').filter(l => !/^import\s+\w+/.test(l)).join('\n').trim() + '\n';
if (delegate.includes(MARK)) delegate = delegate.slice(0, delegate.indexOf(MARK)).trimEnd() + '\n';
for (const imp of imports) if (!delegate.split('\n').some(l => l.trim() === imp.trim())) delegate = imp + '\n' + delegate;
writeFileSync(delegatePath, delegate + '\n' + MARK + '\n' + plugin);
console.log('플러그인 코드 붙임: AppDelegate.swift');

// 2) 스토리보드
const sbPath = join(appDir, 'Base.lproj', 'Main.storyboard');
let sb = readFileSync(sbPath, 'utf8');
if (!sb.includes('customClass="MainViewController"')) {
  const before = sb;
  sb = sb.replace(/customClass="CAPBridgeViewController"\s+customModule="Capacitor"/,
    'customClass="MainViewController" customModule="App" customModuleProvider="target"');
  if (sb === before) {
    console.error('Main.storyboard에서 CAPBridgeViewController를 찾지 못했어요. README의 "직접 바꾸기" 단계를 따라 주세요.');
  } else {
    writeFileSync(sbPath, sb);
    console.log('첫 화면 변경: Main.storyboard → MainViewController');
  }
}

// 3) 권한 문구
const plistPath = join(appDir, 'Info.plist');
let plist = readFileSync(plistPath, 'utf8');
const keys = {
  NSCameraUsageDescription: '노출을 재기 위해 카메라를 사용합니다.',
  NSLocationWhenInUseUsageDescription: '컷마다 촬영 위치를 기록하기 위해 위치를 사용합니다.',
};
let added = 0;
for (const [k, v] of Object.entries(keys)) {
  if (plist.includes(`<key>${k}</key>`)) continue;
  plist = plist.replace(/<\/dict>\s*<\/plist>\s*$/, `\t<key>${k}</key>\n\t<string>${v}</string>\n</dict>\n</plist>\n`);
  added++;
}
if (added) { writeFileSync(plistPath, plist); console.log(`권한 문구 ${added}개 추가: Info.plist`); }
console.log('완료. `npm run open`으로 Xcode를 여세요.');
