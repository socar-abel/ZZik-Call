import SnapKit
import Foundation
import UIKit
import AVFoundation
import Photos
// MLkit
import MLKitTextRecognitionKorean
import MLKitVision
// Indicator View
import NVActivityIndicatorView


// 전화 모드, 기본 모드
enum AppMode {
    case callingMode
    case normalMode
}


class MainViewController: UIViewController {
    var didCall = false
    var imageToDeliver: UIImage?
    var phoneNumber: String? = nil
    // CIContext 를 만드는건 코스트가 많이 들어서 처음에 선언하고 재사용 하는 것이 좋다.
    let ciContext = CIContext()
    var testCount = 1
    
    let elementBoxDrawing = ElementBoxDrawing()
    let textRecognize = TextRecognizing()
    
    let cameraShootImage = UIImage(named: "cameraShootImage2")
    let changeModeImage = UIImage(named: "changeMode3")
    //lazy var newImage = changeModeImage?.resize(newWidth: 80)
    
//    enum UserStates {
//        case beforeTakePictures
//        case afterTakePictures
//    }
    
//    var userState: UserStates?
    var didSetupConstraints = false
    
    var captureDevice: AVCaptureDevice?
    var captureSession: AVCaptureSession?
    var deviceInput: AVCaptureDeviceInput?
    var photoOutput: AVCapturePhotoOutput?
    var setting: AVCapturePhotoSettings?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    let mainDispatchQueue = DispatchQueue.main
    let globalDispatchQueue = DispatchQueue.global()
    
    var videoOutput: AVCaptureVideoDataOutput?
    var orientation: AVCaptureVideoOrientation = .portrait
    let videoQueue = DispatchQueue(label: "Video Camera Queue")
    
    var recognizedPhotoScale: CGFloat = 1.0
    let maxPhotoScale: CGFloat = 3.0
    let minPhotoScale: CGFloat = 1.0
    
    let blueBlackBackgroundColor = UIColor(red: 7/255, green: 13/255, blue: 56/255, alpha: 1.0)
     
    
    // safe area
    lazy var safetyArea: UIView = {
        let view = UIView()
        view.backgroundColor = blueBlackBackgroundColor
        return view
    }()

    let cameraSuperScrollView: UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .black
        //view.backgroundColor = UIColor(white: 1, alpha: 0)
        return view
    }()

    // 카메라 들어갈 뷰
    let cameraView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .black
        return view
    }()

    let boxOnOffView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 1, alpha: 0)
        //view.backgroundColor = .blue
        return view
    }()

    let boxOnImage = UIImage(named: "boxOnImage")
    let boxOffImage = UIImage(named: "boxOffImage")

    lazy var boxOnOffButton: UIButton = {
       let button = UIButton()
        button.setImage(boxOffImage, for: .normal)
        button.alpha = 0.8
        return button
    }()

    var currentBoxOnOff: Bool = false

    // 하단 버튼들이 들어갈 footer 스택 뷰
    lazy var footerView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.spacing = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = blueBlackBackgroundColor
        view.alignment = .fill
        view.distribution = .equalSpacing
        return view
    }()
    
    // footer 에 왼쪽, 중간, 오른쪽 뷰
    lazy var footerLeftView: UIView = {
        let view = UIView()
        view.backgroundColor = blueBlackBackgroundColor
        return view
    }()

    lazy var footerCenterView: UIView = {
        let view = UIView()
        view.backgroundColor = blueBlackBackgroundColor
        return view
    }()
    
    lazy var footerRightView: UIView = {
        let view = UIView()
        view.backgroundColor = blueBlackBackgroundColor
        return view
    }()

    // footer 에 들어갈 전면, 후면 반전 버튼
    let galleryButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("갤러리", for: .normal)
        button.backgroundColor = .gray
        button.setTitleColor(.white, for: .normal)
        return button
    }()

    lazy var cameraShootButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        //button.setTitle("촬영", for: .normal)
        button.setImage(cameraShootImage, for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = blueBlackBackgroundColor
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    lazy var changeModeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        //button.setTitle("화면 전환", for: .normal)
        button.setImage(changeModeImage, for: .normal)

        
        button.backgroundColor = blueBlackBackgroundColor
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    var currentAppMode: AppMode = .callingMode
    var framePreviewSubLayer = CALayer()
    var recognizeResult: Text?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.navigationController?.navigationBar.barStyle = .black
        overrideUserInterfaceStyle = .dark
        currentBoxOnOff = false
        currentAppMode = .callingMode
        
        // 상단 네비게이션 바 세팅
        self.setNavigationBar()
        
        // UI 세팅
        self.setUI()
   
        // 앨범에 접근할 권한 요청
        self.getPhotoLibraryAuthorization()
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinch(_:)))
        let tapFocus = UITapGestureRecognizer(target: self, action: #selector(self.tapCameraFocusing(_:)))
        
        view.addGestureRecognizer(pinch)
        view.addGestureRecognizer(tapFocus)
        
        cameraShootButton.addTarget(self, action: #selector(tapCameraShootButton(_:)), for: .touchDown)
        galleryButton.addTarget(self, action: #selector(tapGalleryButton), for: .touchDown)
        changeModeButton.addTarget(self, action: #selector(tapChangeModeButton), for: .touchDown)
        boxOnOffButton.addTarget(self, action: #selector(tapBoxOnOffButton), for: .touchDown)
    }
    
    
    // AVFoundation camera setting
    func setCamera() {
        print("setting Camera")
        guard let captureDevice = getDefaultCamera() else {
            
            return
        }
        
        self.captureDevice = captureDevice
        
        do {
            captureSession = AVCaptureSession()
            captureSession?.sessionPreset = .photo
            deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            photoOutput = AVCapturePhotoOutput()
            setting = AVCapturePhotoSettings()
            
            // video 추가
            videoOutput = AVCaptureVideoDataOutput()
            videoOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)]
            

            // 공식문서를 읽고 추가한 코드
            videoOutput?.alwaysDiscardsLateVideoFrames = true
            
            // Sets the sample buffer delegate and the queue for invoking callbacks.
            videoOutput?.setSampleBufferDelegate(self, queue: videoQueue)
            guard let videoOutput = videoOutput else { return }
            
            captureSession?.addOutput(videoOutput)
            
            
            guard let input = deviceInput, let output = photoOutput else {return}
            
            captureSession?.addInput(input)
            captureSession?.addOutput(output)
            
            guard let session = captureSession else {return}
            
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            guard let previewLayer = previewLayer else {
                print("preview layer error")
                return
            }
            
            previewLayer.addSublayer(framePreviewSubLayer)
            
            // startRunning 은 UI 쓰레드를 방해할 수 있기 때문에 다른 쓰레드에 담아줌
            globalDispatchQueue.async {
                // 재 촬영 버튼을 누른다면 다시 start 해주도록 나중에 구현해야 함.
                session.startRunning()
            }
            
            mainDispatchQueue.async {
                previewLayer.frame = self.cameraView.frame
                self.cameraView.layer.addSublayer(previewLayer)
            }
            
        } catch {
            showAccessAuthorization()
            print("setting Camera Error")
        }
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // user state 세팅
        //self.userState = .beforeTakePictures
        // 카메라 불러오기
        self.setCamera()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("view will disappear")
        super.viewWillDisappear(animated)
        overrideUserInterfaceStyle = .dark
        globalDispatchQueue.async {
            self.captureSession?.stopRunning()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    static func instance() -> MainViewController {
        let mainViewController = MainViewController()
        return mainViewController
    }

    
}


// 익스텐션
extension MainViewController: AVCapturePhotoCaptureDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // 네비게이션 바 세팅
    func setNavigationBar() {
        self.navigationController?.navigationBar.barStyle = .black
        //self.navigationItem.title = "메인 화면"
        self.navigationController?.navigationBar.topItem?.title = "전화 모드"
        self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        self.navigationController?.navigationBar.tintColor = .white
        view.backgroundColor = blueBlackBackgroundColor
        
        let settingButton = UIBarButtonItem(image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(tapSettingButton))
        let informationButton = UIBarButtonItem(image: UIImage(systemName: "info.circle"),
            style: .plain,
            target: self,
            action: #selector(tapInformationButton))
        
        navigationItem.rightBarButtonItem = settingButton
        navigationItem.leftBarButtonItem = informationButton
        
    }
    
    
    @objc func tapSettingButton(_ sender: UIButton) {
        
    }
    
    
    @objc func tapInformationButton(_ sender: UIButton) {
        
    }
    
        
    // UI 배치, StackView 배치
    func setUI() {
        safetyArea.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(safetyArea)
        view.backgroundColor = blueBlackBackgroundColor
        
        
        if #available(iOS 11, *) {
            let guide = view.safeAreaLayoutGuide
            safetyArea.topAnchor.constraint(equalTo: guide.topAnchor).isActive = true
            safetyArea.bottomAnchor.constraint(equalTo: guide.bottomAnchor).isActive = true
            safetyArea.leadingAnchor.constraint(equalTo: guide.leadingAnchor).isActive = true
            safetyArea.trailingAnchor.constraint(equalTo: guide.trailingAnchor).isActive = true
            
        } else {
            safetyArea.topAnchor.constraint(equalTo: topLayoutGuide.topAnchor).isActive = true
            safetyArea.bottomAnchor.constraint(equalTo: bottomLayoutGuide.bottomAnchor).isActive = true
            safetyArea.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            safetyArea.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        }
        

        
        safetyArea.addSubview(cameraSuperScrollView)
        safetyArea.addSubview(footerView)
        
        
        
        cameraSuperScrollView.addSubview(cameraView)
        cameraSuperScrollView.addSubview(boxOnOffView)
        
        
        boxOnOffView.addSubview(boxOnOffButton)
        
        
        
        footerView.addArrangedSubview(footerLeftView)
        footerView.addArrangedSubview(footerCenterView)
        footerView.addArrangedSubview(footerRightView)
        
        footerLeftView.addSubview(galleryButton)
        footerCenterView.addSubview(cameraShootButton)
        footerRightView.addSubview(changeModeButton)
        
        
        view.setNeedsUpdateConstraints()
    }
    
    // SnapKit 으로 Constraint 설정
    override func updateViewConstraints() {
        if (!didSetupConstraints) {
            
            cameraSuperScrollView.snp.makeConstraints{ make in
                make.top.left.right.equalTo(safetyArea)
                make.height.equalTo(view.frame.width * 4/3)
                make.bottom.equalTo(self.footerView.snp.top)
            }
            
            cameraView.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview()
                make.width.equalToSuperview()
                make.height.equalToSuperview()
            }

            boxOnOffView.snp.makeConstraints { make in
                make.bottom.left.right.equalTo(cameraSuperScrollView.frameLayoutGuide)
                make.height.equalTo(100)
            }
            
            boxOnOffButton.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-10)
            }
            
            footerView.snp.makeConstraints { (make) in
                //make.height.equalTo(200)
                make.bottom.left.right.equalTo(safetyArea)
                make.top.equalTo(self.cameraView.snp.bottom)
            }
            
            footerLeftView.snp.makeConstraints { make in
                make.width.equalTo(self.view).multipliedBy(0.30)
            }
            
            footerCenterView.snp.makeConstraints { make in
                make.width.equalTo(self.view).multipliedBy(0.30)
            }
            
            footerRightView.snp.makeConstraints { make in
                make.width.equalTo(self.view).multipliedBy(0.30)
            }
            
            galleryButton.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
            
            cameraShootButton.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
            
            changeModeButton.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
        
            
            didSetupConstraints = true
        }
        
        print("main camera view")
        print(cameraView.bounds.size.width)
        print(cameraView.bounds.size.height)

        super.updateViewConstraints()

    }
    
    
    // iphone 버전 별로 Camera Type 이 다르기 때문에 버전 별로 최적의 device camera 찾기
    // https://developer.apple.com/documentation/avfoundation/avcapturedevice/2361508-default
    func getDefaultCamera() -> AVCaptureDevice? {
        
        var deviceTypes: [AVCaptureDevice.DeviceType]!
        if #available(iOS 11.1, *)
        { deviceTypes = [.builtInTrueDepthCamera, .builtInDualCamera, .builtInWideAngleCamera] }
        else
        { deviceTypes = [.builtInDualCamera, .builtInWideAngleCamera] }
        let discoverySession = AVCaptureDevice.DiscoverySession( deviceTypes: deviceTypes, mediaType: .video, position: .unspecified )
        let devices = discoverySession.devices
        guard !devices.isEmpty else { fatalError("Missing capture devices.")}
        
        return devices.first(where: { device in device.position == .back })!
    }
    
    

    // 사진 앨범 접근 권한 요청
    func getPhotoLibraryAuthorization() {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("not authorized error")
                // 나중에 "앱을 다시 시작해보세요" 같은 에러 처리 구현해줘야겠다.
                self.mainDispatchQueue.async {
                    self.showAccessAuthorization()
                }
                return
            }
        }
    }
    
    
    // 사진을 찍고나서 호출되는 delegate 메서드
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard error == nil else {
            showUnknownErrorAlert()
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            showUnknownErrorAlert()
            return
        }
        
        let outputImage = UIImage(data: imageData)
        guard let outputImage = outputImage else {
            showUnknownErrorAlert()
            return
        }
        
        self.imageToDeliver = outputImage
        
        // globalQueue 에서 Session stop
        globalDispatchQueue.async {
            self.captureSession?.stopRunning()
        }
        
        self.elementBoxDrawing.removeFrames(layer: self.framePreviewSubLayer)
        
        // mainQueue 쓰레드에서 UI 작업
        mainDispatchQueue.async {
            self.cameraView.layer.contents = outputImage
            // 보내줄 때 scale 1로 초기화
            self.recognizedPhotoScale = 1.0
        }
        
        // 사진을 찍으면 자동으로 저장
        // Asynchronously runs a block that requests changes to the photo library.
        PHPhotoLibrary.shared().performChanges({
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .photo, data: imageData, options: nil)
        }, completionHandler: nil)
        
        //userState = .afterTakePictures
        
        
        // 전화 모드 일때
        if currentAppMode == .callingMode {
            // 전화번호를 인식했으면 전화를 건다.
            globalDispatchQueue.async {
                self.textRecognize.recognizeText(uiImage: outputImage) { [weak self] result in
                    guard let result = result else { return }
                    self?.phoneNumber = self?.textRecognize.getPhoneNumber(result)
                    
                    self?.mainDispatchQueue.async {
                        // 뷰 dim 처리
                        //showDimView()
                        
                        // 전화번호를 인식했으면
                        if let number = self?.phoneNumber {
                            // call 에 completion handler로 pushToNextPage 를 넣었음
                            self?.call(phoneNumber: number, outputImage: outputImage)
                            self?.pushToNextPageWithOutputImage()
                        }
                        // 전화번호를 인식 못했으면
                        else {
                            let alert = UIAlertController(title:"전화를 걸 수 없습니다", message: "인식한 전화번호가 없어요.", preferredStyle: .alert)
                            let okButton = UIAlertAction(title: "확인", style: .default) { (action) in
                                self?.dismiss(animated: true, completion: nil)
                                self?.pushToNextPageWithOutputImage()
                            }
                            alert.addAction(okButton)
                            self?.present(alert, animated: true, completion: nil)
                        }
                    }
                }
            }
        }
        // 기본 모드 일때
        else {
            self.pushToNextPageWithOutputImage()
        }
        
        
    }
    
    
    // 촬영한 이미지를 가지고 다음 페이지로 넘기는 함수
    func pushToNextPageWithOutputImage() {
        guard let outputImage = self.imageToDeliver else {
            return
        }
        // 넘어가기
        let recognizeViewController = RecognizeViewController()
        print("다음 페이지로 넘길 때 height, width \(outputImage.size.height) , \(outputImage.size.width)")

        recognizeViewController.receivedImage = outputImage
        self.navigationController?.pushViewController(recognizeViewController, animated: true)
    }


    // 촬영 버튼 클릭 이벤트
    @IBAction func tapCameraShootButton(_ sender: UIButton) {
        guard let setting = setting else { return }
        photoOutput?.capturePhoto(with: setting, delegate: self)
    }
    
    
    // 갤러리 버튼 클릭 이벤트 -> 앨범에 접근, 근데 현재 딜레이가 좀 있음.
    @IBAction func tapGalleryButton(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.modalPresentationStyle = .fullScreen

        guard UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) else {
            showUnknownErrorAlert()
            return
        }

        imagePicker.delegate = self
        imagePicker.sourceType = .savedPhotosAlbum
        
        globalDispatchQueue.async {
            self.captureSession?.stopRunning()
        }
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    // 앨범에서 사진을 선택한 뒤 실행되는 delegate 메서드
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            
            // 문자 인식 페이지로 넘어감
            let recognizeViewController = RecognizeViewController()
            recognizeViewController.receivedImage = image
            
            dismiss(animated: false, completion: nil)
            self.navigationController?.pushViewController(recognizeViewController, animated: false)
            
        }
        else { showUnknownErrorAlert() }
    }
    
    // 갤러리 픽을 취소했을때
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        globalDispatchQueue.async {
            self.captureSession?.startRunning()
        }
        dismiss(animated: true, completion: nil)
        //self.navigationController?.popViewController(animated: true)
    }
    

    
    func drawAllElement(result: Text?, imageSize: CGSize) {
        guard let result = result else {
            showUnknownErrorAlert()
            return
        }
 
        for block in result.blocks {
            for line in block.lines {
                for element in line.elements {
                    let scaledElementBoxSize = elementBoxDrawing.scaleElementBoxSize(elementFrame: element.frame, imageSize: imageSize, viewFrame: cameraView.frame)
                    elementBoxDrawing.drawElementBox(scaledElementBoxSize, framePreviewSubLayer)
                }
            }
        }
    }
}



extension UIImage {
    // 이미지 회전 에러가 났을 때 원래대로 돌려줄 회전 함수
    func rotateImage(radians: Float) -> UIImage? {
            var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
            // Trim off the extremely small float value to prevent core graphics from rounding it up
            newSize.width = floor(newSize.width)
            newSize.height = floor(newSize.height)

            UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
            let context = UIGraphicsGetCurrentContext()!

            // Move origin to middle
            context.translateBy(x: newSize.width/2, y: newSize.height/2)
            // Rotate around middle
            context.rotate(by: CGFloat(radians))
            // Draw the image at its center
            self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))

            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return newImage
        }
}



// About Video Image Buffer
extension MainViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // Methods for receiving sample buffers from, and monitoring the status of, a video data output.
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        connection.videoOrientation = .portrait
//        lazy var sampleSizes: Int = -1
//        lazy var totalSampleSizes: Int = -1
//        do {
//            try sampleSizes = sampleBuffer.sampleSizes().first ?? -1
//
//        } catch { print("captureOutputError") }
//
//        totalSampleSizes = sampleBuffer.totalSampleSize
//
//        // 이게 왜 -1, 0 이 나올까?
//        print("sampleSizes() ", sampleSizes)
//        print("totalSampleSizes() ", totalSampleSizes)
//        print()
        
        // 박스 On 일때
        if currentBoxOnOff {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            let ciImage: CIImage = CIImage(cvImageBuffer: imageBuffer)
            guard let cgImage: CGImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return }
            var uiImage: UIImage = UIImage(cgImage: cgImage)
//            // 이미지 회전 에러가 났다면 제대로 다시 돌려줌.
//            if uiImage.size.width > uiImage.size.height {
//                guard let newImage = uiImage.rotateImage(radians: .pi/2) else { return }
//                uiImage = newImage
//            }
            
            textRecognize.recognizeText(uiImage: uiImage) { [weak self] result in
                guard let result = result else { return }
                self?.mainDispatchQueue.async {
                    self?.elementBoxDrawing.removeFrames(layer: self?.framePreviewSubLayer)
                    self?.drawAllElement(result: result, imageSize: uiImage.size)
                }
            }
        }
        // box Off 일때
        else {
            self.mainDispatchQueue.async {
                self.elementBoxDrawing.removeFrames(layer: self.framePreviewSubLayer)
            }
        }
    }
    
    
}



// About Gesture
extension MainViewController {
    // 카메라 줌 인, 줌 아웃 구현
    // 사진 줌 인, 줌 아웃 구현
    // device.videoZoomFactor 에 접근하려면 lock / unlock 과정이 필요함
    // https://developer.apple.com/documentation/avfoundation/avcapturedevice
    // https://gist.github.com/yusuke024/3b5a89835deab5b9027efea794b80a45
    @objc func handlePinch(_ pinch: UIPinchGestureRecognizer) {
        // [코드 1]
        guard let device = self.captureDevice else {return}
        
        var initialScale: CGFloat = device.videoZoomFactor
        let minAvailableZoomScale = 1.0
        let maxAvailableZoomScale = device.maxAvailableVideoZoomFactor
        
        do {
            try device.lockForConfiguration()
            if(pinch.state == UIPinchGestureRecognizer.State.began){
                initialScale = device.videoZoomFactor
            }
            else {
                if(initialScale*(pinch.scale) < minAvailableZoomScale){
                    device.videoZoomFactor = minAvailableZoomScale
                }
                else if(initialScale*(pinch.scale) > maxAvailableZoomScale){
                    device.videoZoomFactor = maxAvailableZoomScale
                }
                else {
                    device.videoZoomFactor = initialScale * (pinch.scale)
                }
            }
            pinch.scale = 1.0
        } catch {
            return
        }
        device.unlockForConfiguration()
        
        
//        // 사진을 찍기 전, 카메라가 실시간으로 보이고 있는 상황에서의 zoom 구현
//        if (self.userState == .beforeTakePictures) {
//            // [코드 1] 이 있던 자리
//        }
//        // 사진을 찍은 후, 그러니까 사진의 결과가 카메라 뷰에 올라왔을 때의 zoom 구현
//        // 이 코드는 없애도 되지 않을까 ?
//        else if (self.userState == .afterTakePictures) {
//            mainDispatchQueue.async {
//                if (pinch.state == .began || pinch.state == .changed){
//                    // 확대
//                    if(self.recognizedPhotoScale < self.maxPhotoScale && pinch.scale > 1.0){
//                        self.cameraView.transform = self.cameraView.transform.scaledBy(x: pinch.scale, y: pinch.scale)
//                        self.recognizedPhotoScale *= pinch.scale
//                    }
//                    // 축소
//                    else if (self.recognizedPhotoScale > self.minPhotoScale && pinch.scale < 1.0) {
//                        self.cameraView.transform  = self.cameraView.transform.scaledBy(x: pinch.scale, y: pinch.scale)
//                        self.recognizedPhotoScale *= pinch.scale
//                    }
//                }
//                pinch.scale = 1.0
//                print(self.recognizedPhotoScale)
//            }
//        }

    }
    
    
    // 카메라 포커싱 메서드
    // https://developer.apple.com/documentation/avfoundation/avcapturedevice/1385853-focuspointofinterest
    // 이 공식문서에 따르면 이 왼쪽 위가 (0, 0) 이고 오른쪽 아래가 (1, 1) 인 좌표계를 사용한다.
    @objc func tapCameraFocusing(_ sender: UITapGestureRecognizer) {
        guard let device = self.captureDevice else {
            showUnknownErrorAlert()
            return
        }

        if (sender.state == .ended) {
            let thisFocusPoint = sender.location(in: cameraView)
            focusAnimationAt(thisFocusPoint)

            let focus_x = thisFocusPoint.x / cameraView.frame.size.width
            let focus_y = thisFocusPoint.y / cameraView.frame.size.height
            
            if (device.isFocusModeSupported(.autoFocus) && device.isFocusPointOfInterestSupported) {
                do {
                    try device.lockForConfiguration()
                    device.focusMode = .autoFocus
                    device.focusPointOfInterest = CGPoint(x: focus_x, y: focus_y)

                    if (device.isExposureModeSupported(.autoExpose) && device.isExposurePointOfInterestSupported) {
                        device.exposureMode = .autoExpose;
                        device.exposurePointOfInterest = CGPoint(x: focus_x, y: focus_y);
                     }

                    device.unlockForConfiguration()
                } catch {
                    showUnknownErrorAlert()
                }
            }
        }
    }
    
    
    // 카메라 포커싱 애니메이션
    func focusAnimationAt(_ point: CGPoint) {
        print("focus Animation 호출")
        let focusView = UIImageView(image: UIImage(named: "aim"))
        focusView.center = point
        cameraView.addSubview(focusView)

        focusView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)

        UIView.animate(withDuration: 0.4, delay: 0.0, options: .curveEaseInOut, animations: {
//            focusView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            focusView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        }) { (success) in
            UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseInOut, animations: {
                focusView.alpha = 0.0
            }) { (success) in
                focusView.removeFromSuperview()
            }
        }
    }
    
    
    @objc func tapBoxOnOffButton(_ sender: UIButton) {
        // 버튼 이미지 바뀌는 코드도 추가해야 함
        if currentBoxOnOff {
            currentBoxOnOff = false
            self.boxOnOffButton.setImage(boxOffImage, for: .normal)
        }
        else {
            currentBoxOnOff = true
            self.boxOnOffButton.setImage(boxOnImage, for: .normal)
        }
    }
    
    
    @objc func tapChangeModeButton(_ sender: UIButton) {
        if currentAppMode == .callingMode {
            currentAppMode = .normalMode
            mainDispatchQueue.async {
                self.navigationController?.navigationBar.topItem?.title = "기본 모드"
            }
            
        }
        else {
            currentAppMode = .callingMode
            mainDispatchQueue.async {
                self.navigationController?.navigationBar.topItem?.title = "전화 모드"
            }
            
        }
    }
    
    // 전화 걸기 메서드
    func call(phoneNumber: String, outputImage: UIImage) {
        if let url = NSURL(string: "tel:\(phoneNumber)"), UIApplication.shared.canOpenURL(url as URL) {
            // completion handler 가 전화가 종료된 다음 호출되는게 아니다. url 을 찾았을 때 호출됨.
            // didEnterBackground 활용
            UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
        }
    }
}

extension UINavigationController {
    open override var childForStatusBarHidden: UIViewController? {
        return visibleViewController
    }
    open override var childForStatusBarStyle: UIViewController? {
        return visibleViewController
    }
}



