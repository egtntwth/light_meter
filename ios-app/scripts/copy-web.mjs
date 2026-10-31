// 저장소 루트의 index.html(웹앱)을 앱이 읽는 www/ 폴더로 복사한다.
import { mkdirSync, copyFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const app = join(here, '..');
mkdirSync(join(app, 'www'), { recursive: true });
copyFileSync(join(app, '..', 'index.html'), join(app, 'www', 'index.html'));
console.log('웹앱 복사: ../index.html → www/index.html');
