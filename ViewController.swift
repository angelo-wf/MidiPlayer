
import Cocoa
import AVFoundation

class ViewController: NSViewController, NSWindowDelegate {

  var slider: NSSlider!
  var progress: NSTextField!
  var button: NSButton!
  var loopButton: NSButton!
  var speedMenu: NSPopUpButton!

  var player: AVMIDIPlayer?
  var timer: Timer?
  var loop: Bool = false

  var appDelegate: AppDelegate!
  var window: NSWindow!

  let speeds: [Int] = [25, 33, 50, 75, 100, 150, 200, 300, 400]

  override func loadView() {
    view = NSView(frame: NSMakeRect(0, 0, 400, 104))
    title = "MidiPlayer"
    view.translatesAutoresizingMaskIntoConstraints = false
    setupView()
    appDelegate = (NSApplication.shared.delegate as! AppDelegate)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    reset()
  }

  func setWindow(_ window: NSWindow) {
    self.window = window
    window.delegate = self
    window.contentMinSize = NSSize(width: 400, height: 104)
  }

  func setupView() {
    slider = NSSlider(target: self, action: #selector(sliderChanged))
    view.addSubview(slider)
    slider.translatesAutoresizingMaskIntoConstraints = false

    progress = NSTextField(labelWithString: "0:00 / 0:00")
    progress.alignment = .center
    view.addSubview(progress)
    progress.translatesAutoresizingMaskIntoConstraints = false

    button = NSButton(title: "Play", target: self, action: #selector(playPressed))
    view.addSubview(button)
    button.translatesAutoresizingMaskIntoConstraints = false

    loopButton = NSButton(title: "Loop: Off", target: self, action: #selector(loopToggled))
    view.addSubview(loopButton)
    loopButton.translatesAutoresizingMaskIntoConstraints = false

    speedMenu = NSPopUpButton(title: "", target: self, action: #selector(speedMenuChanged))
    for speed in speeds {
      let menuItem = NSMenuItem(title: "Speed: \(Float(speed) / 100.0)", action: nil, keyEquivalent: "")
      menuItem.tag = speed
      speedMenu.menu!.addItem(menuItem)
    }
    speedMenu.selectItem(withTag: 100)
    view.addSubview(speedMenu)
    speedMenu.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      slider.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8),
      slider.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8),
      slider.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
      slider.heightAnchor.constraint(equalToConstant: 24)
    ])

    NSLayoutConstraint.activate([
      loopButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8),
      loopButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3, constant: -12),
      loopButton.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 8),
      loopButton.heightAnchor.constraint(equalToConstant: 24)
    ])

    NSLayoutConstraint.activate([
      speedMenu.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8),
      speedMenu.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3, constant: -12),
      speedMenu.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 8),
      speedMenu.heightAnchor.constraint(equalToConstant: 24)
    ])

    NSLayoutConstraint.activate([
      progress.leftAnchor.constraint(equalTo: loopButton.rightAnchor, constant: 8),
      progress.rightAnchor.constraint(equalTo: speedMenu.leftAnchor, constant: -8),
      progress.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 12),
      progress.heightAnchor.constraint(equalToConstant: 20)
    ])

    NSLayoutConstraint.activate([
      button.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8),
      button.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8),
      button.topAnchor.constraint(equalTo: progress.bottomAnchor, constant: 8),
      button.heightAnchor.constraint(equalToConstant: 24)
    ])
  }

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    reset()
    return true
  }

  func loadFile(url: URL) {
    reset()
    player = try? AVMIDIPlayer(contentsOf: url, soundBankURL: nil)
    player?.prepareToPlay()
    if let tag = speedMenu.selectedItem?.tag {
      player?.rate = Float(tag) / 100.0
    }
    if player != nil {
      appDelegate.addRecentUrl(url: url)
      title = url.lastPathComponent
      window.setTitleWithRepresentedFilename(url.path)
      progress.stringValue = "0:00 / \(getTimeString(player!.duration))"
      // do async, prevents stop callback from halting playback
      DispatchQueue.main.async {
        self.play()
      }
    }
  }

  func reset() {
    pause()
    player = nil
    progress.stringValue = "0:00 / 0:00"
    slider.floatValue = 0.0
    title = "MidiPlayer"
  }

  @objc func update() {
    if player == nil {
      return
    }
    progress.stringValue = "\(getTimeString(player!.currentPosition)) / \(getTimeString(player!.duration))"
    slider.floatValue = Float(player!.currentPosition / player!.duration)
  }

  func getTimeString(_ value: Double) -> String {
    let minutes = floor(value / 60)
    let seconds = floor(value - (minutes * 60))
    let extraZero = seconds < 10 ? "0" : ""
    return "\(Int(minutes)):\(extraZero)\(Int(seconds))"
  }

  @objc func sliderChanged() {
    if player == nil {
      return
    }
    player!.currentPosition = Double(slider.floatValue) * player!.duration
    progress.stringValue = "\(getTimeString(player!.currentPosition)) / \(getTimeString(player!.duration))"
  }

  @objc func loopToggled() {
    loop = !loop
    loopButton.title = "Loop: \(loop ? "On" : "Off")"
    appDelegate.setLoopItem(loop: loop)
  }

  @objc func speedMenuChanged() {
    if player == nil {
      return
    }
    if let tag = speedMenu.selectedItem?.tag {
      player?.rate = Float(tag) / 100.0
    }
  }

  @objc func playPressed() {
    if player == nil { return }
    if player!.isPlaying {
      pause()
    } else {
      play()
    }
  }

  func play() {
    if player == nil { return }
    button.title = "Pause"
    appDelegate.setPlayPauseItem(playing: true)
    player!.play {
      DispatchQueue.main.async {
        self.pause()
        if self.player != nil {
          if self.player!.currentPosition > self.player!.duration - 0.1 {
            self.player!.currentPosition = 0
            if self.loop {
              self.play()
            }
          }
        }
        self.update()
      }
    }
    timer = Timer.scheduledTimer(timeInterval: 1 / 8, target: self, selector: #selector(update), userInfo: nil, repeats: true)
    RunLoop.main.add(timer!, forMode: .common)
  }

  func pause() {
    button.title = "Play"
    appDelegate.setPlayPauseItem(playing: false)
    player?.stop()
    timer?.invalidate()
    timer = nil
  }
}
