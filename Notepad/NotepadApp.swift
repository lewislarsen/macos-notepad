import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Main App Entry Point

@main
struct NotepadApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Using Settings to suppress the default SwiftUI window since we're managing windows manually via AppKit
        Settings { EmptyView() }
    }
}

// MARK: - Application Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        setupMenuBar()
        
        // Create initial window if none exist
        if NSApp.windows.isEmpty {
            createNewWindow()
        }
    }
    
    /// Handles opening files when dragged onto the app icon or opened via Finder
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            // Always create a new window for files opened from Finder
            createNewWindow()
            
            // Load the file into the newly created window
            if let newWindow = NSApp.windows.last,
               let controller = newWindow.contentViewController as? NotepadViewController {
                controller.loadFile(url)
            }
        }
    }
    
    /// Handles Quit from Dock, Cmd+Q, or App Menu - checks all windows for unsaved changes
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        for window in sender.windows {
            if let controller = window.delegate as? NotepadViewController {
                var shouldTerminate = false
                controller.checkUnsaved {
                    shouldTerminate = true
                }
                // If user clicks "Cancel" in any window, abort the quit
                if !shouldTerminate {
                    return .terminateCancel
                }
            }
        }
        return .terminateNow
    }
    
    /// Closes app when last window is closed, removing it from Dock
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    // MARK: - Window Management
    
    /// Creates a new blank Notepad window
    @objc func createNewWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Untitled - Notepad"
        window.isReleasedWhenClosed = false
        window.identifier = NSUserInterfaceItemIdentifier(UUID().uuidString)
        
        let viewController = NotepadViewController()
        window.contentViewController = viewController
        window.delegate = viewController
        
        window.makeKeyAndOrderFront(nil)
    }
    
    /// Displays custom About panel
    @objc func showCustomAboutPanel(_ sender: Any?) {
        let credits = "A copy of Microsoft Windows classic Notepad for macOS.\nMade by Lewis Larsen."
        let attributedCredits = NSAttributedString(
            string: credits,
            attributes: [
                .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
                .foregroundColor: NSColor.labelColor
            ]
        )
        
        let options: [NSApplication.AboutPanelOptionKey: Any] = [
            .credits: attributedCredits,
            .applicationName: "Notepad"
        ]
        
        NSApp.orderFrontStandardAboutPanel(options: options)
    }
    
    // MARK: - Menu Bar Setup
    
    private func setupMenuBar() {
        let mainMenu = NSMenu()
        
        // App Menu
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Notepad", action: #selector(showCustomAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        mainMenu.addItem(withSubmenu: appMenu)
        
        // File Menu
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(withTitle: "New", action: #selector(AppDelegate.createNewWindow), keyEquivalent: "n")
        fileMenu.addItem(withTitle: "Open...", action: #selector(NotepadViewController.openDocument(_:)), keyEquivalent: "o")
        fileMenu.addItem(withTitle: "Save", action: #selector(NotepadViewController.saveDocument), keyEquivalent: "s")
        fileMenu.addItem(withTitle: "Save As...", action: #selector(NotepadViewController.saveDocumentAs), keyEquivalent: "S")
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        mainMenu.addItem(withSubmenu: fileMenu)
        
        // Edit Menu
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Find...", action: #selector(NotepadViewController.showFindPanel(_:)), keyEquivalent: "f")
        editMenu.addItem(withTitle: "Find and Replace...", action: #selector(NotepadViewController.showFindAndReplacePanel(_:)), keyEquivalent: "h")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Time/Date", action: #selector(NotepadViewController.insertTimeDate), keyEquivalent: "\u{F708}") // F5 key
        mainMenu.addItem(withSubmenu: editMenu)
        
        // Format Menu
        let formatMenu = NSMenu(title: "Format")
        formatMenu.addItem(withTitle: "Word Wrap", action: #selector(NotepadViewController.toggleWordWrap), keyEquivalent: "")
        formatMenu.addItem(withTitle: "Font...", action: #selector(NotepadViewController.showFontPanel), keyEquivalent: "")
        mainMenu.addItem(withSubmenu: formatMenu)
        
        // View Menu
        let viewMenu = NSMenu(title: "View")
        let zoomMenu = NSMenu(title: "Zoom")
        zoomMenu.addItem(withTitle: "Zoom In", action: #selector(NotepadViewController.zoomIn), keyEquivalent: "+")
        zoomMenu.addItem(withTitle: "Zoom Out", action: #selector(NotepadViewController.zoomOut), keyEquivalent: "-")
        zoomMenu.addItem(withTitle: "Restore Default Zoom", action: #selector(NotepadViewController.zoomReset), keyEquivalent: "0")
        viewMenu.addItem(withTitle: "Zoom", action: nil, keyEquivalent: "").submenu = zoomMenu
        viewMenu.addItem(NSMenuItem.separator())
        viewMenu.addItem(withTitle: "Status Bar", action: #selector(NotepadViewController.toggleStatusBarAction), keyEquivalent: "")
        mainMenu.addItem(withSubmenu: viewMenu)
        
        // Window Menu
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenu.addItem(NSMenuItem.separator())
        windowMenu.addItem(withTitle: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")
        mainMenu.addItem(withSubmenu: windowMenu)
        NSApp.windowsMenu = windowMenu
        
        NSApp.mainMenu = mainMenu
    }
}

// MARK: - Main View Controller

class NotepadViewController: NSViewController, NSWindowDelegate, NSTextViewDelegate {
    
    // UI Components
    private var textView: NSTextView!
    private var scrollView: NSScrollView!
    private var statusBar: NSTextField!
    
    // Document State
    private var isDocumentEdited = false
    private var currentFileURL: URL?
    
    // UserDefaults Keys
    private let kFontName = "Notepad_FontName"
    private let kFontSize = "Notepad_FontSize"
    private let kWordWrap = "Notepad_WordWrap"
    private let kShowStatus = "Notepad_ShowStatus"
    
    // MARK: - Lifecycle
    
    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        applyPersistedSettings()
    }
    
    // MARK: - Window Delegate
    
    /// Handles window close attempts - checks for unsaved changes
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        var canClose = false
        checkUnsaved { canClose = true }
        return canClose
    }
    
    /// Checks if this window is empty and can be reused for opening files
    func isEmptyAndUntitled() -> Bool {
        return textView.string.isEmpty && currentFileURL == nil && !isDocumentEdited
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Status Bar
        statusBar = NSTextField(labelWithString: "  Ln 1, Col 1")
        statusBar.frame = NSRect(x: 0, y: 0, width: view.bounds.width, height: 22)
        statusBar.autoresizingMask = [.width, .maxYMargin]
        statusBar.font = NSFont.systemFont(ofSize: 11)
        statusBar.wantsLayer = true
        statusBar.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        view.addSubview(statusBar)
        
        // Scroll View
        scrollView = NSScrollView(frame: NSRect(x: 0, y: 22, width: view.bounds.width, height: view.bounds.height - 22))
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.borderType = .noBorder
        
        // Text View
        textView = NSTextView(frame: scrollView.bounds)
        textView.delegate = self
        textView.isRichText = false
        textView.allowsUndo = true
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.textContainerInset = NSSize(width: 5, height: 5)
        textView.usesFindBar = true
        
        scrollView.documentView = textView
        view.addSubview(scrollView)
    }
    
    private func applyPersistedSettings() {
        // Apply saved font
        let fontName = UserDefaults.standard.string(forKey: kFontName) ?? "Monaco"
        let fontSize = UserDefaults.standard.double(forKey: kFontSize)
        let size = fontSize == 0 ? 12.0 : fontSize
        textView.font = NSFont(name: fontName, size: CGFloat(size))
        
        // Apply word wrap setting
        let wordWrap = UserDefaults.standard.bool(forKey: kWordWrap)
        textView.textContainer?.widthTracksTextView = wordWrap
        
        // Apply status bar visibility (default: visible)
        let showStatus = UserDefaults.standard.object(forKey: kShowStatus) == nil ? true : UserDefaults.standard.bool(forKey: kShowStatus)
        toggleStatusBar(visible: showStatus)
    }
    
    // MARK: - Menu Validation
    
    /// Updates menu item checkmarks based on current state
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(toggleWordWrap) {
            menuItem.state = (textView.textContainer?.widthTracksTextView ?? false) ? .on : .off
        } else if menuItem.action == #selector(toggleStatusBarAction) {
            menuItem.state = statusBar.isHidden ? .off : .on
        }
        return true
    }
    
    // MARK: - Zoom Actions
    
    @objc func zoomIn() {
        modifyFontSize(delta: 2)
    }
    
    @objc func zoomOut() {
        modifyFontSize(delta: -2)
    }
    
    @objc func zoomReset() {
        updateFont(name: textView.font?.fontName, size: 12)
    }
    
    private func modifyFontSize(delta: CGFloat) {
        let currentSize = textView.font?.pointSize ?? 12
        let newSize = max(4, currentSize + delta) // Minimum font size of 4
        updateFont(name: textView.font?.fontName, size: newSize)
    }
    
    private func updateFont(name: String?, size: CGFloat) {
        let fontName = name ?? "Monaco"
        let newFont = NSFont(name: fontName, size: size) ?? NSFont.systemFont(ofSize: size)
        textView.font = newFont
        
        // Persist font settings
        UserDefaults.standard.set(newFont.fontName, forKey: kFontName)
        UserDefaults.standard.set(newFont.pointSize, forKey: kFontSize)
    }
    
    // MARK: - Format Actions
    
    @objc func toggleWordWrap(_ sender: NSMenuItem) {
        let newState = sender.state == .off
        textView.textContainer?.widthTracksTextView = newState
        UserDefaults.standard.set(newState, forKey: kWordWrap)
    }
    
    @objc func showFontPanel() {
        NSFontManager.shared.target = self
        NSFontManager.shared.orderFrontFontPanel(self)
    }
    
    @objc func changeFont(_ sender: NSFontManager?) {
        if let newFont = sender?.convert(textView.font ?? NSFont.systemFont(ofSize: 12)) {
            updateFont(name: newFont.fontName, size: newFont.pointSize)
        }
    }
    
    // MARK: - View Actions
    
    @objc func toggleStatusBarAction(_ sender: NSMenuItem) {
        let newState = sender.state == .off
        toggleStatusBar(visible: newState)
        UserDefaults.standard.set(newState, forKey: kShowStatus)
    }
    
    private func toggleStatusBar(visible: Bool) {
        statusBar.isHidden = !visible
        let statusHeight: CGFloat = visible ? 22 : 0
        scrollView.frame = NSRect(
            x: 0,
            y: statusHeight,
            width: view.bounds.width,
            height: view.bounds.height - statusHeight
        )
    }
    
    // MARK: - Edit Actions
    
    @objc func insertTimeDate() {
        let dateString = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
        textView.insertText(dateString, replacementRange: textView.selectedRange())
    }
    
    @objc func showFindPanel(_ sender: Any?) {
        // Create a menu item with the proper tag for find
        let menuItem = NSMenuItem()
        menuItem.tag = NSTextFinder.Action.showFindInterface.rawValue
        textView.performFindPanelAction(menuItem)
    }
    
    @objc func showFindAndReplacePanel(_ sender: Any?) {
        // Create a menu item with the proper tag for find and replace
        let menuItem = NSMenuItem()
        menuItem.tag = NSTextFinder.Action.showReplaceInterface.rawValue
        textView.performFindPanelAction(menuItem)
    }
    
    // MARK: - File Operations
    
    @objc func openDocument(_ sender: Any?) {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.plainText]
        openPanel.allowsMultipleSelection = false
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                // Create new window
                let window = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                    styleMask: [.titled, .closable, .miniaturizable, .resizable],
                    backing: .buffered,
                    defer: false
                )
                window.center()
                window.isReleasedWhenClosed = false
                window.identifier = NSUserInterfaceItemIdentifier(UUID().uuidString)
                
                let viewController = NotepadViewController()
                window.contentViewController = viewController
                window.delegate = viewController
                
                // Load the file
                viewController.loadFile(url)
                
                // Show the window
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
    
    @objc func saveDocument() {
        if let url = currentFileURL {
            saveToFile(url: url)
        } else {
            saveDocumentAs()
        }
    }
    
    @objc func saveDocumentAs() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = currentFileURL?.lastPathComponent ?? "Untitled.txt"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                self.saveToFile(url: url)
            }
        }
    }
    
    private func saveToFile(url: URL) {
        do {
            try textView.string.write(to: url, atomically: true, encoding: .utf8)
            currentFileURL = url
            isDocumentEdited = false
            updateTitle()
        } catch {
            showErrorAlert(message: "Unable to save file: \(error.localizedDescription)")
        }
    }
    
    func loadFile(_ url: URL) {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            textView.string = content
            currentFileURL = url
            isDocumentEdited = false
            updateTitle()
            updateCursorLocation()
        } catch {
            showErrorAlert(message: "Unable to open file: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Text View Delegate
    
    func textDidChange(_ notification: Notification) {
        isDocumentEdited = true
        updateTitle()
        updateCursorLocation()
    }
    
    func textViewDidChangeSelection(_ notification: Notification) {
        updateCursorLocation()
    }
    
    // MARK: - UI Updates
    
    private func updateCursorLocation() {
        let text = textView.string as NSString
        let location = textView.selectedRange().location
        let substring = text.substring(to: min(location, text.length))
        let lines = substring.components(separatedBy: "\n")
        let lineNumber = lines.count
        let columnNumber = (lines.last?.count ?? 0) + 1
        
        statusBar.stringValue = "  Ln \(lineNumber), Col \(columnNumber)"
    }
    
    private func updateTitle() {
        let filename = currentFileURL?.lastPathComponent ?? "Untitled"
        let editedIndicator = isDocumentEdited ? "*" : ""
        view.window?.title = "\(editedIndicator)\(filename) - Notepad"
        view.window?.isDocumentEdited = isDocumentEdited
    }
    
    // MARK: - Unsaved Changes Handling
    
    /// Checks for unsaved changes and prompts user if necessary
    func checkUnsaved(proceed: @escaping () -> Void) {
        if !isDocumentEdited {
            proceed()
            return
        }
        
        let alert = NSAlert()
        alert.messageText = "Do you want to save the changes?"
        alert.informativeText = "Your changes to \"\(currentFileURL?.lastPathComponent ?? "Untitled")\" will be lost if you don't save them."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Don't Save")
        alert.addButton(withTitle: "Cancel")
        
        // Run modal on the window if available
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            // Save
            saveDocument()
            proceed()
        } else if response == .alertSecondButtonReturn {
            // Don't Save
            proceed()
        }
        // Cancel - do nothing, which prevents the close/quit
    }
    
    // MARK: - Error Handling
    
    private func showErrorAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// MARK: - NSMenu Extension

extension NSMenu {
    /// Convenience method to add a menu item with a submenu
    func addItem(withSubmenu menu: NSMenu) {
        let item = NSMenuItem()
        item.submenu = menu
        self.addItem(item)
    }
}
