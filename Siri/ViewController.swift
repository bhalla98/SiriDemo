import UIKit
import Speech
import AVKit


class ViewController: UIViewController, SFSpeechRecognizerDelegate{
	
	@IBOutlet weak var textView: UITextView!
    @IBOutlet weak var microphoneButton: UIButton!
    @IBOutlet weak var stopRecordingButton: UIButton!
    @IBOutlet weak var recordingLabel: UILabel!
	
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest? //Handles SR request
    private var recognitionTask: SFSpeechRecognitionTask?                 //Handles result of SR request
    private let audioEngine = AVAudioEngine()                            //Provides audio input
    
    
    override func viewDidLoad() {
		super.viewDidLoad()
        
        microphoneButton.isEnabled = false //disabling microphone button until SR activated
        speechRecognizer?.delegate = self //calling the ViewController itself
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            var isButtonEnabled = false
            
            switch authStatus {
            case.authorized:
                isButtonEnabled = true
            
            case.denied:
                isButtonEnabled = false
                print("User denied acces to speech recognition")
                
            case.restricted:
                isButtonEnabled = false
                print("Speech recognition restricted in this device")
                
            case.notDetermined:
                isButtonEnabled = false
                print("Speech recognition is not authorized")
            
            }
            
            OperationQueue.main.addOperation {                       //method that enables microphone if authorized
                self.microphoneButton.isEnabled = isButtonEnabled   //else disables microphone
            }
            
        }
            
	}
    
    @IBAction func microphoneTapped(_ sender: UIButton) {
        if audioEngine.isRunning {                     //if audioEngine is running
            audioEngine.stop()                        //stop audioEngine
            recognitionRequest?.endAudio()           //terminate input audio to cognitionRequest
            microphoneButton.isEnabled = false      //disable microphone button
            recordingLabel.text = "Recording In Progress!"
        } else {                                     //if audioEngine is working
            startRecording()                        //call startRecording()
            recordingLabel.text = "Recording In Progress!"
            microphoneButton.isEnabled = false
            stopRecordingButton.isEnabled = true
        }
    }
    
    @IBAction func stopRecording(_ sender: UIButton) {
        recordingLabel.text = "Tap To Record!"
        stopRecordingButton.isEnabled = false
        microphoneButton.isEnabled = true
        let audioSession = AVAudioSession.sharedInstance()
        try! audioSession.setActive(false)
    }
    
    //triggering SR, and checking the availability of SR while creating SR task
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphoneButton.isEnabled = true
        } else {
            microphoneButton.isEnabled = false
        }
    }
    
    func startRecording(){
        
        if recognitionTask != nil{                   //checks if recognitionTask is running
            recognitionTask?.cancel()               //if so, then cancel task and recognition
            recognitionTask = nil
    
        }
        
        let audioSession = AVAudioSession.sharedInstance()                //prepares for audio recording
        do{
           try audioSession.setCategory(AVAudioSessionCategoryRecord)    //sets category of session as recording
           try audioSession.setMode(AVAudioSessionModeMeasurement)      //sets mode as measurement
           try audioSession.setActive(true, with: .notifyOthersOnDeactivation)  //activates audio session
        } catch{
            print("Audio Session properties weren't set because of an error")  
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {   //checks if audio engine has audio input for recording
            fatalError("AudioEngine has no input node")     //if no audio input, then report fatal error
        }
        
        guard let recognitionRequest = recognitionRequest else {         //checks if recognitionRequst is instantiated
            fatalError("Unable to create SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true   //tells recognitionRequest to report partial results of
                                                              //speech recognition as user speaks
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result,error) in    //starts recognition
            var isFinal = false
            
            if result != nil {
                self.textView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
        
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.microphoneButton.isEnabled = true
            }
        })

        let recordingFormat = inputNode.outputFormat(forBus: 0)         //adding audio input to recognitionRequest
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        
        audioEngine.prepare()                       //prepares and starts audioEngine
        
        do {
            try audioEngine.start()
        }   catch {
            print("AudioEngine couldn't start because of an error")
        }
        
        textView.text = "Say something, I'm listening!"
        
    }   //startRecording() ends
        
}   //class ViewController ends 

















