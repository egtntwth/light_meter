import AVFoundation
import Capacitor

// 앱이 뜰 때 LightMeter 플러그인을 등록하는 첫 화면.
// Main.storyboard의 첫 화면 클래스가 이걸로 바뀌어 있어야 한다 (scripts/patch-ios.mjs가 바꿈).
class MainViewController: CAPBridgeViewController {
    override open func capacitorDidLoad() {
        bridge?.registerPluginInstance(LightMeterPlugin())
    }
}

// 웹앱(index.html)에서 window.Capacitor.Plugins.LightMeter로 부르는 플러그인.
//  start({x, y, width, height})  후면 카메라를 켜고, 웹 화면의 뷰파인더 자리 뒤에 미리보기를 깐다
//  setFrame({x, y, width, height})  뷰파인더 크기·위치가 바뀌면 미리보기를 옮긴다
//  setPoint({x, y})  측광점(웹 화면 좌표). 아이폰 자동노출이 이 점을 기준으로 맞춘다
//  stop()
//  'exposure' 이벤트(0.2초마다): t(초), iso, N(조리개), offset(자동노출 목표와의 차이, EV)
@objc(LightMeterPlugin)
public class LightMeterPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "LightMeterPlugin"
    public let jsName = "LightMeter"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "start", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stop", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setFrame", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setPoint", returnType: CAPPluginReturnPromise)
    ]

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "light_meter.camera")
    private var device: AVCaptureDevice?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var timer: Timer?

    private func rect(_ call: CAPPluginCall) -> CGRect {
        return CGRect(x: call.getDouble("x") ?? 0,
                      y: call.getDouble("y") ?? 0,
                      width: call.getDouble("width") ?? 0,
                      height: call.getDouble("height") ?? 0)
    }

    @objc func start(_ call: CAPPluginCall) {
        let frame = rect(call)
        AVCaptureDevice.requestAccess(for: .video) { granted in
            guard granted else {
                call.reject("카메라 권한이 없어요. 설정 → light_meter → 카메라를 켜 주세요.")
                return
            }
            self.sessionQueue.async {
                if self.device == nil {
                    guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                          let input = try? AVCaptureDeviceInput(device: dev) else {
                        call.reject("후면 카메라를 찾지 못했어요.")
                        return
                    }
                    self.session.beginConfiguration()
                    self.session.sessionPreset = .high
                    if self.session.canAddInput(input) { self.session.addInput(input) }
                    self.session.commitConfiguration()
                    self.device = dev
                }
                if !self.session.isRunning { self.session.startRunning() }
                DispatchQueue.main.async {
                    self.attachPreview(frame)
                    self.startTimer()
                    call.resolve(["aperture": Double(self.device?.lensAperture ?? 0)])
                }
            }
        }
    }

    @objc func stop(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = nil
            self.previewLayer?.removeFromSuperlayer()
            self.previewLayer = nil
        }
        sessionQueue.async {
            if self.session.isRunning { self.session.stopRunning() }
        }
        call.resolve()
    }

    @objc func setFrame(_ call: CAPPluginCall) {
        let frame = rect(call)
        DispatchQueue.main.async {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.previewLayer?.frame = frame
            CATransaction.commit()
            call.resolve()
        }
    }

    @objc func setPoint(_ call: CAPPluginCall) {
        let x = call.getDouble("x") ?? 0
        let y = call.getDouble("y") ?? 0
        DispatchQueue.main.async {
            guard let layer = self.previewLayer, let dev = self.device else {
                call.resolve()
                return
            }
            let local = CGPoint(x: x - layer.frame.minX, y: y - layer.frame.minY)
            let point = layer.captureDevicePointConverted(fromLayerPoint: local)
            self.sessionQueue.async {
                do {
                    try dev.lockForConfiguration()
                    if dev.isExposurePointOfInterestSupported { dev.exposurePointOfInterest = point }
                    if dev.isExposureModeSupported(.continuousAutoExposure) { dev.exposureMode = .continuousAutoExposure }
                    dev.unlockForConfiguration()
                } catch {
                    // 측광점을 못 바꿔도 측광은 계속된다
                }
                call.resolve()
            }
        }
    }

    // 웹뷰를 투명하게 하고, 그 맨 아래 층에 카메라 미리보기를 깐다.
    // 웹 화면은 앱 안에서 뷰파인더 자리만 투명하게 그리므로 그 자리로 미리보기가 보인다.
    private func attachPreview(_ frame: CGRect) {
        guard let webView = bridge?.webView else { return }
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0x1b / 255.0, green: 0x1d / 255.0, blue: 0x1c / 255.0, alpha: 1)
        webView.scrollView.backgroundColor = .clear
        if previewLayer == nil {
            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            webView.layer.insertSublayer(layer, at: 0)
            previewLayer = layer
        }
        previewLayer?.frame = frame
    }

    // 카메라가 지금 쓰는 노출값을 0.2초마다 웹으로 보낸다.
    // 웹 쪽 계산: EV100 = log2(N²/t) − log2(ISO/100) + offset
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self = self, let d = self.device else { return }
            let t = CMTimeGetSeconds(d.exposureDuration)
            guard t > 0 else { return }
            self.notifyListeners("exposure", data: [
                "t": t,
                "iso": Double(d.iso),
                "N": Double(d.lensAperture),
                "offset": Double(d.exposureTargetOffset)
            ])
        }
    }
}
