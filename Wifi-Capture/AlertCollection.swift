import Foundation
import UIKit

extension UIViewController {

    // 알 수 없는 에러 처리
    func showUnknownErrorAlert() {
        let alert = UIAlertController(title:"죄송합니다", message: "알 수 없는 에러가 발생했어요.", preferredStyle: .alert)
        let okButton = UIAlertAction(title: "확인", style: .default) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        alert.addAction(okButton)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    // 카메라, 앨범에 접근 권한 설정을 하지 않았을 경우 알림
    func showAccessAuthorization() {
        let alert = UIAlertController(title:"앱을 실행할 수 없습니다.", message: "카메라와 앨범 접근 권한을 허용해주세요", preferredStyle: .alert)
        let settingButton = UIAlertAction(title: "설정", style: .default) { (action) in
            self.dismiss(animated: true, completion: nil)

            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                self.showUnknownErrorAlert()
                return
            }
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
            else {
                self.showUnknownErrorAlert()
            }
        }
        
        alert.addAction(settingButton)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    // 인식한 전화번호가 없을 때
    func showThereIsNoPhoneNumberAlert() {
        let alert = UIAlertController(title:"전화를 걸 수 없습니다", message: "인식한 전화번호가 없어요.", preferredStyle: .alert)
        let okButton = UIAlertAction(title: "확인", style: .default) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        let detailButton = UIAlertAction(title: "자세히", style: .default) { (action) in
            self.dismiss(animated: false, completion: nil)
            self.showDetailInstructions()
        }
        alert.addAction(okButton)
        alert.addAction(detailButton)
        self.present(alert, animated: true, completion: nil)
    }
    
    // 자세한 설명
    func showDetailInstructions() {
        
    }
    
    
    // 토스트 메시지 생성
    func makeToast(_ message: String) {
        let toastLabel = UITextView(frame: CGRect(x: self.view.frame.size.width/2 - 80, y: 175, width: 160, height: 30))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds = true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 0.5, delay: 1.0, options: .curveEaseOut,
                       animations: { toastLabel.alpha = 0.0 },
                       completion: {(isCompleted) in toastLabel.removeFromSuperview() })
    }
    
    
    // 선택할게 없을 때 토스트 메시지
    func showNoSelectToast() {
        makeToast("사진에서 글자를 인식하지 못했습니다")
    }
    
    
    // 전체선택 했을 때 토스트 메시지
    func showSelectAllToast() {
        makeToast("텍스트 박스를 모두 선택합니다")
    }
    
    
    // 복사할게 없을 때 토스트 메시지
    func showNoCopyToast() {
        makeToast("복사할 텍스트가 없습니다")
    }
    
    
    // 복사했을 때 토스트 메시지
    func showCopyToastt(copiedText: String) {
        var text = copiedText
        if copiedText.count >= 10 {
            let idx = copiedText.index(copiedText.startIndex, offsetBy: 9)
            text = String(copiedText[..<idx])
            text += "..."
        }
        
        let textView = UITextView(frame: CGRect(x: self.view.frame.size.width/2 - 80, y: 175, width: 160, height: 45))
        textView.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        textView.textColor = UIColor.white
        textView.textAlignment = .center
        textView.text = "\"\(text)\" \n 클립보드에 복사했습니다"
        textView.alpha = 1.0
        textView.layer.cornerRadius = 10
        textView.clipsToBounds = true
        self.view.addSubview(textView)
        UIView.animate(withDuration: 0.5, delay: 1.0, options: .curveEaseOut,
                       animations: { textView.alpha = 0.0 },
                       completion: {(isCompleted) in textView.removeFromSuperview() })
        
    }
    
}
