
import Cocoa
import UniformTypeIdentifiers

class AppDelegate: NSObject, NSApplicationDelegate {

  var window: NSWindow!
  var app: NSApplication!
  var viewController: ViewController!

  var recentMenu: NSMenu!
  var playPauseItem: NSMenuItem!
  var loopMenuItem: NSMenuItem!

  var fileToOpen: String?

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    app = NSApplication.shared

    NSWindow.allowsAutomaticWindowTabbing = false

    recentMenu = NSMenu(title: "Open Recent")
    recentMenu.autoenablesItems = false
    recreateRecentMenu()

    app.mainMenu = createMenu()

    viewController = ViewController()
    window = NSWindow(contentViewController: viewController)
    window.setFrameAutosaveName("MidiPlayerMain")
    viewController.setWindow(window)

    app.activate(ignoringOtherApps: true)

    if let toOpen = fileToOpen {
      _ = application(app, openFile: toOpen)
    } else {
      openFile()
    }
    fileToOpen = nil
  }

  func createMenu() -> NSMenu {
    let mainMenu = NSMenu(title: "")

    let appMenu = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    appMenu.submenu = NSMenu(title: "")
    appMenu.submenu?.items = [
      NSMenuItem(title: "About MidiPlayer", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""),
      NSMenuItem.separator(),
      NSMenuItem(title: "Services", action: nil, keyEquivalent: ""),
      NSMenuItem.separator(),
      NSMenuItem(title: "Hide", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"),
      createMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h", modifier: [.command, .option]),
      NSMenuItem(title: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: ""),
      NSMenuItem.separator(),
      NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    ]
    app.servicesMenu = NSMenu(title: "Services")
    appMenu.submenu?.items[2].submenu = app.servicesMenu
    mainMenu.addItem(appMenu)

    let fileMenu = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
    fileMenu.submenu = NSMenu(title: "File")
    fileMenu.submenu?.items = [
      NSMenuItem(title: "Open", action: #selector(openFile), keyEquivalent: "o"),
      NSMenuItem(title: "Open Recent", action: nil, keyEquivalent: ""),
      NSMenuItem.separator(),
      NSMenuItem(title: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
    ]
    fileMenu.submenu?.items[1].submenu = recentMenu
    mainMenu.addItem(fileMenu)

    let playbackMenu = NSMenuItem(title: "Playback", action: nil, keyEquivalent: "")
    playbackMenu.submenu = NSMenu(title: "Playback")
    playPauseItem = NSMenuItem(title: "Play / Pause", action: #selector(ViewController.playPressed), keyEquivalent: "p")
    loopMenuItem = NSMenuItem(title: "Loop", action: #selector(ViewController.loopToggled), keyEquivalent: "l")
    playbackMenu.submenu?.items = [playPauseItem, loopMenuItem]
    mainMenu.addItem(playbackMenu)

    let windowMenu = NSMenuItem(title: "Window", action: nil, keyEquivalent: "")
    windowMenu.submenu = NSMenu(title: "Window")
    windowMenu.submenu?.items = [
      NSMenuItem(title: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m"),
      NSMenuItem(title: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: ""),
      createMenuItem(title: "Toggle Full Screen", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f", modifier: [.command, .control]),
      NSMenuItem.separator(),
      NSMenuItem(title: "Bring All To Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")
    ]
    app.windowsMenu = windowMenu.submenu
    mainMenu.addItem(windowMenu)

    let helpMenu = NSMenuItem(title: "Help", action: nil, keyEquivalent: "")
    helpMenu.submenu = NSMenu(title: "Help")
    helpMenu.submenu?.items = []
    app.helpMenu = helpMenu.submenu
    mainMenu.addItem(helpMenu)

    return mainMenu
  }

  func createMenuItem(title: String, action: Selector?, keyEquivalent: String, modifier: NSEvent.ModifierFlags) -> NSMenuItem {
    let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
    item.keyEquivalentModifierMask = modifier
    return item
  }

  func recreateRecentMenu() {
    recentMenu.removeAllItems()
    var count = 0
    for url in NSDocumentController.shared.recentDocumentURLs {
      let menuItem = NSMenuItem(title: url.lastPathComponent, action: #selector(openRecentFile(_:)), keyEquivalent: "")
      menuItem.tag = count
      let image = NSWorkspace.shared.icon(forFile: url.path)
      image.size = NSSize(width: 16, height: 16)
      menuItem.image = image
      recentMenu.addItem(menuItem)
      count += 1
    }
    let clearItem = NSMenuItem(title: "Clear Menu", action: #selector(clearRecents), keyEquivalent: "")
    if count > 0 {
      recentMenu.addItem(NSMenuItem.separator())
    } else {
      clearItem.isEnabled = false
    }
    recentMenu.addItem(clearItem)
  }

  func setPlayPauseItem(playing: Bool) {
    playPauseItem.title = playing ? "Pause" : "Play"
  }

  func setLoopItem(loop: Bool) {
    loopMenuItem.state = loop ? .on : .off
  }

  func addRecentUrl(url: URL) {
    NSDocumentController.shared.noteNewRecentDocumentURL(url)
    recreateRecentMenu()
  }

  @objc func clearRecents() {
    NSDocumentController.shared.clearRecentDocuments(self)
    recreateRecentMenu()
  }

  @objc func openRecentFile(_ sender: NSMenuItem?) {
    if let menuItem = sender {
      let url = NSDocumentController.shared.recentDocumentURLs[menuItem.tag]
      _ = application(app, openFile: url.path)
    }
  }

  @objc func openFile() {
    let dialog = NSOpenPanel()
    dialog.allowedContentTypes = [UTType.midi]
    if dialog.runModal() == .OK {
      if let res = dialog.url {
        viewController.loadFile(url: res)
      }
      window.makeKeyAndOrderFront(self)
    }
  }

  func application(_ sender: NSApplication, openFile fileName: String) -> Bool {
    if viewController == nil {
      fileToOpen = fileName
      return true
    }
    viewController.loadFile(url: URL(fileURLWithPath: fileName))
    window.makeKeyAndOrderFront(self)
    return true
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    viewController.reset()
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag {
      openFile()
    }
    return true
  }
}
