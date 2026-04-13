import AppKit
import Combine
import Foundation
import SwiftUI
import WebKit

enum SessionState: String {
  case idle
  case running
  case paused
  case alerting

  var label: String {
    switch self {
    case .idle:
      return "未开始"
    case .running:
      return "进行中"
    case .paused:
      return "已暂停"
    case .alerting:
      return "提醒中"
    }
  }
}

enum ReminderSound {
  static let defaultName = "Glass"
  static let availableNames = [
    "Basso", "Blow", "Bottle", "Frog", "Funk", "Glass",
    "Hero", "Morse", "Ping", "Pop", "Purr", "Sosumi",
    "Submarine", "Tink"
  ]

  static func play(named name: String) {
    if let sound = NSSound(named: NSSound.Name(name)) {
      sound.stop()
      sound.play()
    } else {
      NSSound.beep()
    }
  }
}

struct ReminderConfig: Identifiable, Codable, Hashable {
  var id: UUID
  var title: String
  var intervalMinutes: Double
  var snoozeMinutes: Double
  var soundEnabled: Bool
  var soundName: String
  var message: String

  init(
    id: UUID,
    title: String,
    intervalMinutes: Double,
    snoozeMinutes: Double,
    soundEnabled: Bool,
    soundName: String,
    message: String
  ) {
    self.id = id
    self.title = title
    self.intervalMinutes = intervalMinutes
    self.snoozeMinutes = snoozeMinutes
    self.soundEnabled = soundEnabled
    self.soundName = soundName
    self.message = message
  }

  enum CodingKeys: String, CodingKey {
    case id
    case title
    case intervalMinutes
    case snoozeMinutes
    case soundEnabled
    case soundName
    case message
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(UUID.self, forKey: .id)
    title = try container.decode(String.self, forKey: .title)
    intervalMinutes = try container.decode(Double.self, forKey: .intervalMinutes)
    snoozeMinutes = try container.decode(Double.self, forKey: .snoozeMinutes)
    soundEnabled = try container.decode(Bool.self, forKey: .soundEnabled)
    soundName = try container.decodeIfPresent(String.self, forKey: .soundName) ?? ReminderSound.defaultName
    message = try container.decode(String.self, forKey: .message)
  }

  static func neckRotationExample() -> ReminderConfig {
    ReminderConfig(
      id: UUID(),
      title: "活动脖子",
      intervalMinutes: 25,
      snoozeMinutes: 5,
      soundEnabled: true,
      soundName: ReminderSound.defaultName,
      message: """
      ## 活动一下脖子

      请轻轻地：

      - 左右转动脖子
      - 放松肩膀
      - 调整坐姿
      """
    )
  }

  static func newTemplate(index: Int) -> ReminderConfig {
    ReminderConfig(
      id: UUID(),
      title: "新提醒 \(index)",
      intervalMinutes: 30,
      snoozeMinutes: 5,
      soundEnabled: true,
      soundName: ReminderSound.defaultName,
      message: """
      ## 新提醒

      在这里输入 Markdown 内容。
      """
    )
  }
}

final class ReminderStore: ObservableObject {
  @Published var reminders: [ReminderConfig] = [] {
    didSet { persist() }
  }
  @Published var selectedReminderID: UUID?
  @Published var menuBarReminderID: UUID? {
    didSet {
      UserDefaults.standard.set(menuBarReminderID?.uuidString, forKey: Self.menuBarReminderDefaultsKey)
    }
  }
  @Published private(set) var storageFileURL: URL

  private static let storagePathDefaultsKey = "storageFilePath"
  private static let menuBarReminderDefaultsKey = "menuBarReminderID"

  init() {
    let path = UserDefaults.standard.string(forKey: Self.storagePathDefaultsKey) ?? Self.defaultStorageFilePath()
    storageFileURL = Self.resolveStorageFileURL(from: path)
    if
      let raw = UserDefaults.standard.string(forKey: Self.menuBarReminderDefaultsKey),
      let uuid = UUID(uuidString: raw)
    {
      menuBarReminderID = uuid
    }
    load()
  }

  static func defaultStorageFilePath() -> String {
    FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent("Documents", isDirectory: true)
      .appendingPathComponent("my-health-manager", isDirectory: true)
      .appendingPathComponent("settings.json", isDirectory: false)
      .path
  }

  var selectedReminder: ReminderConfig? {
    guard let selectedReminderID else { return reminders.first }
    return reminders.first(where: { $0.id == selectedReminderID }) ?? reminders.first
  }

  var menuBarReminder: ReminderConfig? {
    guard let menuBarReminderID else { return reminders.first }
    return reminders.first(where: { $0.id == menuBarReminderID }) ?? reminders.first
  }

  func select(_ id: UUID) {
    selectedReminderID = id
  }

  func addReminder() {
    let reminder = ReminderConfig.newTemplate(index: reminders.count + 1)
    reminders.append(reminder)
    selectedReminderID = reminder.id
    if menuBarReminderID == nil {
      menuBarReminderID = reminder.id
    }
  }

  func removeSelectedReminder() {
    guard let selectedReminderID else { return }
    reminders.removeAll { $0.id == selectedReminderID }
    self.selectedReminderID = reminders.first?.id
    if menuBarReminderID == selectedReminderID {
      menuBarReminderID = reminders.first?.id
    }
    persist()
  }

  func update(_ reminder: ReminderConfig) {
    guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
    reminders[index] = reminder
  }

  func updateStorageFilePath(_ path: String) {
    let resolved = Self.resolveStorageFileURL(from: path)
    guard resolved != storageFileURL else { return }
    storageFileURL = resolved
    UserDefaults.standard.set(resolved.path, forKey: Self.storagePathDefaultsKey)
    load()
  }

  func storageDirectoryURL() -> URL {
    storageFileURL.deletingLastPathComponent()
  }

  func selectMenuBarReminder(_ id: UUID?) {
    menuBarReminderID = id
  }

  private func load() {
    guard
      let data = try? Data(contentsOf: storageFileURL),
      let decoded = try? JSONDecoder().decode([ReminderConfig].self, from: data),
      !decoded.isEmpty
    else {
      reminders = [ReminderConfig.neckRotationExample()]
      selectedReminderID = reminders.first?.id
      persist()
      return
    }

    reminders = decoded
    selectedReminderID = decoded.first?.id
    if menuBarReminder == nil {
      menuBarReminderID = decoded.first?.id
    }
  }

  private func persist() {
    let directory = storageFileURL.deletingLastPathComponent()
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    guard let data = try? JSONEncoder().encode(reminders) else { return }
    try? data.write(to: storageFileURL, options: .atomic)
  }

  private static func resolveStorageFileURL(from path: String) -> URL {
    let expanded = NSString(string: path).expandingTildeInPath
    return URL(fileURLWithPath: expanded, isDirectory: false)
  }
}

enum HealthModule: String, CaseIterable, Identifiable {
  case reminders
  case settings

  var id: String { rawValue }

  var title: String {
    switch self {
    case .reminders:
      return "健康提醒"
    case .settings:
      return "全局设置"
    }
  }

  var subtitle: String {
    switch self {
    case .reminders:
      return "管理多个自定义提醒"
    case .settings:
      return "软件级配置与存储"
    }
  }

  var iconName: String {
    switch self {
    case .reminders:
      return "list.bullet.clipboard"
    case .settings:
      return "gearshape"
    }
  }
}

final class ReminderManager: ObservableObject {
  @Published private(set) var stateByID: [UUID: SessionState] = [:]
  @Published private(set) var remainingByID: [UUID: Int] = [:]
  @Published private(set) var currentAlertReminderID: UUID?

  private let store: ReminderStore
  private var timer: Timer?
  private var wakeObserver: NSObjectProtocol?
  private var storeObserver: AnyCancellable?
  private var dueDateByID: [UUID: Date] = [:]
  private var pausedSecondsByID: [UUID: Int] = [:]
  private var alertQueue: [UUID] = []

  init(store: ReminderStore) {
    self.store = store
    synchronize(with: store.reminders)
    storeObserver = store.$reminders
      .receive(on: RunLoop.main)
      .sink { [weak self] reminders in
        self?.synchronize(with: reminders)
      }
    startTicker()
    observeWakeEvents()
  }

  deinit {
    timer?.invalidate()
    if let wakeObserver {
      NotificationCenter.default.removeObserver(wakeObserver)
    }
  }

  func state(for reminderID: UUID) -> SessionState {
    stateByID[reminderID] ?? .idle
  }

  func remainingSeconds(for reminderID: UUID) -> Int {
    remainingByID[reminderID] ?? 0
  }

  func formattedRemaining(for reminderID: UUID) -> String {
    let seconds = max(remainingSeconds(for: reminderID), 0)
    return String(format: "%02d:%02d", seconds / 60, seconds % 60)
  }

  func start(_ reminder: ReminderConfig) {
    let interval = max(60, Int(reminder.intervalMinutes * 60))
    dueDateByID[reminder.id] = Date().addingTimeInterval(TimeInterval(interval))
    remainingByID[reminder.id] = interval
    pausedSecondsByID[reminder.id] = 0
    stateByID[reminder.id] = .running
    objectWillChange.send()
  }

  func pause(_ reminder: ReminderConfig) {
    guard state(for: reminder.id) == .running else { return }
    pausedSecondsByID[reminder.id] = max(remainingSeconds(for: reminder.id), 1)
    dueDateByID[reminder.id] = nil
    stateByID[reminder.id] = .paused
  }

  func resume(_ reminder: ReminderConfig) {
    guard state(for: reminder.id) == .paused else { return }
    let interval = max(pausedSecondsByID[reminder.id] ?? 1, 1)
    dueDateByID[reminder.id] = Date().addingTimeInterval(TimeInterval(interval))
    remainingByID[reminder.id] = interval
    pausedSecondsByID[reminder.id] = 0
    stateByID[reminder.id] = .running
  }

  func stop(_ reminder: ReminderConfig) {
    dueDateByID[reminder.id] = nil
    remainingByID[reminder.id] = 0
    pausedSecondsByID[reminder.id] = 0
    stateByID[reminder.id] = .idle
    removeFromAlertFlow(reminder.id)
  }

  func remindNow(_ reminder: ReminderConfig) {
    triggerAlert(for: reminder)
  }

  func dismissAlertAndRestart(_ reminder: ReminderConfig) {
    guard state(for: reminder.id) == .alerting else { return }
    removeFromAlertFlow(reminder.id)
    start(reminder)
  }

  func snooze(_ reminder: ReminderConfig) {
    let interval = max(60, Int(reminder.snoozeMinutes * 60))
    removeFromAlertFlow(reminder.id)
    dueDateByID[reminder.id] = Date().addingTimeInterval(TimeInterval(interval))
    remainingByID[reminder.id] = interval
    pausedSecondsByID[reminder.id] = 0
    stateByID[reminder.id] = .running
  }

  func currentAlertReminder() -> ReminderConfig? {
    guard let currentAlertReminderID else { return nil }
    return store.reminders.first(where: { $0.id == currentAlertReminderID })
  }

  func statusText() -> String {
    if let reminder = currentAlertReminder() {
      return "\(reminder.title)提醒中"
    }
    let runningCount = store.reminders.filter { state(for: $0.id) == .running || state(for: $0.id) == .paused }.count
    return runningCount > 0 ? "运行中\(runningCount)项" : "待开始"
  }

  func currentMenuBarSummary(for reminder: ReminderConfig?) -> [String] {
    guard let reminder else {
      return ["未指定菜单栏提醒", "请在全局设置里选择一条提醒"]
    }

    let state = state(for: reminder.id)
    switch state {
    case .idle:
      return [reminder.title, "当前未运行"]
    case .running:
      return [reminder.title, "剩余时间 \(formattedRemaining(for: reminder.id))"]
    case .paused:
      return [reminder.title, "已暂停 · 剩余 \(formattedRemaining(for: reminder.id))"]
    case .alerting:
      return [reminder.title, "正在提醒中"]
    }
  }

  private func startTicker() {
    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
      self?.tick(now: Date())
    }
    RunLoop.main.add(timer!, forMode: .common)
    tick(now: Date())
  }

  private func observeWakeEvents() {
    wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.didWakeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.tick(now: Date())
    }
  }

  private func tick(now: Date) {
    for reminder in store.reminders {
      guard state(for: reminder.id) == .running, let dueDate = dueDateByID[reminder.id] else {
        if state(for: reminder.id) == .idle {
          remainingByID[reminder.id] = 0
        }
        continue
      }

      let seconds = max(Int(dueDate.timeIntervalSince(now).rounded(.down)), 0)
      remainingByID[reminder.id] = seconds
      if now >= dueDate {
        triggerAlert(for: reminder)
      }
    }
  }

  private func triggerAlert(for reminder: ReminderConfig) {
    dueDateByID[reminder.id] = nil
    remainingByID[reminder.id] = 0
    pausedSecondsByID[reminder.id] = 0
    stateByID[reminder.id] = .alerting

    if !alertQueue.contains(reminder.id) {
      alertQueue.append(reminder.id)
    }
    if currentAlertReminderID == nil {
      currentAlertReminderID = reminder.id
    }

    if reminder.soundEnabled {
      ReminderSound.play(named: reminder.soundName)
    }
  }

  private func removeFromAlertFlow(_ reminderID: UUID) {
    alertQueue.removeAll { $0 == reminderID }
    if currentAlertReminderID == reminderID {
      currentAlertReminderID = alertQueue.first
    }
  }

  private func synchronize(with reminders: [ReminderConfig]) {
    let validIDs = Set(reminders.map(\.id))
    dueDateByID = dueDateByID.filter { validIDs.contains($0.key) }
    pausedSecondsByID = pausedSecondsByID.filter { validIDs.contains($0.key) }
    remainingByID = remainingByID.filter { validIDs.contains($0.key) }
    stateByID = stateByID.filter { validIDs.contains($0.key) }
    alertQueue.removeAll { !validIDs.contains($0) }
    if let currentAlertReminderID, !validIDs.contains(currentAlertReminderID) {
      self.currentAlertReminderID = alertQueue.first
    }

    for reminder in reminders where stateByID[reminder.id] == nil {
      stateByID[reminder.id] = .idle
      remainingByID[reminder.id] = 0
    }
  }
}

final class AlertWindowController {
  private var panel: NSPanel?
  private let panelSize = NSSize(width: 460, height: 360)

  func present(manager: ReminderManager, reminder: ReminderConfig, baseDirectoryURL: URL) {
    let panel = panel ?? makePanel()
    let rootView = AlertCardView(manager: manager, reminder: reminder, baseDirectoryURL: baseDirectoryURL)
    panel.contentView = NSHostingView(rootView: rootView)
    position(panel: panel)
    panel.orderFrontRegardless()
    NSApp.activate(ignoringOtherApps: true)
    self.panel = panel
  }

  func dismiss() {
    panel?.orderOut(nil)
  }

  private func makePanel() -> NSPanel {
    let panel = NSPanel(
      contentRect: NSRect(origin: .zero, size: panelSize),
      styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )
    panel.isFloatingPanel = true
    panel.level = .floating
    panel.titleVisibility = .hidden
    panel.titlebarAppearsTransparent = true
    panel.isReleasedWhenClosed = false
    panel.standardWindowButton(.closeButton)?.isHidden = true
    panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
    panel.standardWindowButton(.zoomButton)?.isHidden = true
    return panel
  }

  private func position(panel: NSPanel) {
    let screen = NSApp.keyWindow?.screen ?? NSScreen.main ?? NSScreen.screens.first
    let visibleFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
    let margin: CGFloat = 20
    let origin = NSPoint(
      x: visibleFrame.maxX - panelSize.width - margin,
      y: visibleFrame.maxY - panelSize.height - margin
    )
    panel.setFrame(NSRect(origin: origin, size: panelSize), display: true)
  }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
  private var statusItem: NSStatusItem?
  private weak var mainWindow: NSWindow?
  private var cancellables: Set<AnyCancellable> = []
  private let alertWindowController = AlertWindowController()
  private var isBound = false

  var store: ReminderStore?
  var manager: ReminderManager?

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)
    NSApp.applicationIconImage = AppIconFactory.makeAppIcon(size: 512)
    installStatusItem()
    bindIfNeeded()
  }

  func configure(store: ReminderStore, manager: ReminderManager) {
    self.store = store
    self.manager = manager
    bindIfNeeded()
    updateStatusItem()
  }

  func registerMainWindow(_ window: NSWindow) {
    mainWindow = window
    window.delegate = self
    window.setContentSize(NSSize(width: 1140, height: 720))
    window.center()
  }

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    sender.orderOut(nil)
    NSApp.setActivationPolicy(.accessory)
    return false
  }

  @objc func openMainWindow(_ sender: Any?) {
    NSApp.setActivationPolicy(.regular)
    mainWindow?.makeKeyAndOrderFront(nil)
    mainWindow?.orderFrontRegardless()
    NSApp.activate(ignoringOtherApps: true)
  }

  @objc func quitApp(_ sender: Any?) {
    NSApp.terminate(nil)
  }

  @objc func toggleMenuBarReminder(_ sender: Any?) {
    guard let store, let manager, let reminder = store.menuBarReminder else { return }
    switch manager.state(for: reminder.id) {
    case .idle:
      manager.start(reminder)
    case .running:
      manager.pause(reminder)
    case .paused:
      manager.resume(reminder)
    case .alerting:
      manager.dismissAlertAndRestart(reminder)
    }
  }

  @objc func remindMenuBarReminderNow(_ sender: Any?) {
    guard let store, let manager, let reminder = store.menuBarReminder else { return }
    manager.remindNow(reminder)
  }

  @objc func stopMenuBarReminder(_ sender: Any?) {
    guard let store, let manager, let reminder = store.menuBarReminder else { return }
    manager.stop(reminder)
  }

  private func installStatusItem() {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    if let button = item.button {
      button.image = AppIconFactory.makeStatusBarIcon()
      button.imagePosition = .imageLeading
    }
    statusItem = item
    rebuildStatusMenu()
  }

  private func bindIfNeeded() {
    guard !isBound, let manager else { return }
    isBound = true

    manager.$currentAlertReminderID
      .receive(on: RunLoop.main)
      .sink { [weak self] _ in
        self?.updateAlertPresentation()
        self?.updateStatusItem()
        self?.rebuildStatusMenu()
      }
      .store(in: &cancellables)

    manager.$stateByID
      .receive(on: RunLoop.main)
      .sink { [weak self] _ in
        self?.updateStatusItem()
        self?.rebuildStatusMenu()
      }
      .store(in: &cancellables)

    manager.$remainingByID
      .receive(on: RunLoop.main)
      .sink { [weak self] _ in
        self?.updateStatusItem()
        self?.rebuildStatusMenu()
      }
      .store(in: &cancellables)

    store?.$menuBarReminderID
      .receive(on: RunLoop.main)
      .sink { [weak self] _ in
        self?.rebuildStatusMenu()
      }
      .store(in: &cancellables)
  }

  private func updateAlertPresentation() {
    guard let manager, let store else { return }
    guard let reminder = manager.currentAlertReminder() else {
      alertWindowController.dismiss()
      return
    }
    alertWindowController.present(manager: manager, reminder: reminder, baseDirectoryURL: store.storageDirectoryURL())
  }

  private func updateStatusItem() {
    guard let button = statusItem?.button else { return }
    button.title = ""
    button.toolTip = "我的健康助手"
  }

  private func rebuildStatusMenu() {
    guard let statusItem else { return }
    let menu = NSMenu()
    menu.addItem(NSMenuItem(title: "打开主窗口", action: #selector(openMainWindow(_:)), keyEquivalent: ""))

    if let store, let manager {
      let summary = manager.currentMenuBarSummary(for: store.menuBarReminder)
      menu.addItem(.separator())
      menu.addItem(NSMenuItem(title: summary[0], action: nil, keyEquivalent: ""))
      let detailItem = NSMenuItem(title: summary[1], action: nil, keyEquivalent: "")
      detailItem.isEnabled = false
      menu.addItem(detailItem)
    }

    if let store, let manager, let reminder = store.menuBarReminder {
      let state = manager.state(for: reminder.id)
      menu.addItem(NSMenuItem(title: menuBarPrimaryTitle(for: state), action: #selector(toggleMenuBarReminder(_:)), keyEquivalent: ""))
      menu.addItem(NSMenuItem(title: "立即提醒", action: #selector(remindMenuBarReminderNow(_:)), keyEquivalent: ""))
      menu.addItem(NSMenuItem(title: "停止", action: #selector(stopMenuBarReminder(_:)), keyEquivalent: ""))
    }

    menu.addItem(.separator())
    menu.addItem(NSMenuItem(title: "退出", action: #selector(quitApp(_:)), keyEquivalent: "q"))
    menu.items.forEach { item in
      if item.action != nil {
        item.target = self
      }
    }
    statusItem.menu = menu
  }

  private func menuBarPrimaryTitle(for state: SessionState) -> String {
    switch state {
    case .idle:
      return "开始"
    case .running:
      return "暂停"
    case .paused:
      return "继续"
    case .alerting:
      return "开始下一轮"
    }
  }
}

struct MainWindowAccessor: NSViewRepresentable {
  let onResolve: (NSWindow) -> Void

  func makeNSView(context: Context) -> NSView {
    let view = NSView()
    DispatchQueue.main.async {
      if let window = view.window {
        onResolve(window)
      }
    }
    return view
  }

  func updateNSView(_ nsView: NSView, context: Context) {
    DispatchQueue.main.async {
      if let window = nsView.window {
        onResolve(window)
      }
    }
  }
}

struct MyHealthManagerApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @StateObject private var store: ReminderStore
  @StateObject private var manager: ReminderManager

  init() {
    let store = ReminderStore()
    _store = StateObject(wrappedValue: store)
    _manager = StateObject(wrappedValue: ReminderManager(store: store))
  }

  var body: some Scene {
    WindowGroup("我的健康助手") {
      ContentView(manager: manager)
        .environmentObject(store)
        .background(MainWindowAccessor { window in
          appDelegate.registerMainWindow(window)
        })
        .onAppear {
          appDelegate.configure(store: store, manager: manager)
        }
    }
    .defaultSize(width: 1140, height: 720)
  }
}

struct ContentView: View {
  @ObservedObject var manager: ReminderManager
  @EnvironmentObject private var store: ReminderStore
  @State private var selectedModule: HealthModule = .reminders
  @State private var storagePathDraft: String = ""

  var body: some View {
    HStack(spacing: 0) {
      moduleSidebar
      Divider()
      moduleDetail
    }
    .frame(minWidth: 1140, minHeight: 720)
    .onAppear {
      storagePathDraft = store.storageFileURL.path
    }
    .onChange(of: store.storageFileURL) { newValue in
      storagePathDraft = newValue.path
    }
  }

  private var moduleSidebar: some View {
    VStack(alignment: .leading, spacing: 18) {
      VStack(alignment: .leading, spacing: 6) {
        Text("我的健康助手")
          .font(.system(size: 24, weight: .bold, design: .rounded))
      }

      ForEach(HealthModule.allCases) { module in
        ModuleTabButton(module: module, isSelected: selectedModule == module) {
          selectedModule = module
        }
      }
      Spacer()
    }
    .padding(20)
    .frame(width: 220, alignment: .topLeading)
    .frame(maxHeight: .infinity, alignment: .topLeading)
    .background(Color(nsColor: .controlBackgroundColor))
  }

  @ViewBuilder
  private var moduleDetail: some View {
    switch selectedModule {
    case .reminders:
      HStack(spacing: 0) {
        remindersListPane
        Divider()
        reminderEditorPane
      }
    case .settings:
      globalSettingsPane
    }
  }

  private var remindersListPane: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text("提醒列表")
          .font(.title3.weight(.semibold))
        Spacer()
        Button("新增提醒") {
          store.addReminder()
        }
      }

      ScrollView {
        VStack(spacing: 10) {
          ForEach(store.reminders) { reminder in
            ReminderListRow(
              reminder: reminder,
              state: manager.state(for: reminder.id),
              remainingText: manager.formattedRemaining(for: reminder.id),
              isSelected: store.selectedReminder?.id == reminder.id
            ) {
              store.select(reminder.id)
            }
          }
        }
      }

      if store.reminders.count > 1 {
        Button("删除当前提醒", role: .destructive) {
          store.removeSelectedReminder()
        }
      }
    }
    .padding(20)
    .frame(width: 280, alignment: .topLeading)
    .frame(maxHeight: .infinity, alignment: .topLeading)
  }

  @ViewBuilder
  private var reminderEditorPane: some View {
    if let reminder = store.selectedReminder {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          reminderHeader(reminder)
          sessionCard(reminder)
          settingsCard(reminder)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    } else {
      VStack {
        Text("没有可编辑的提醒")
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }

  private var globalSettingsPane: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        VStack(alignment: .leading, spacing: 8) {
          Text("全局设置")
            .font(.system(size: 30, weight: .bold, design: .rounded))
          Text("这里管理软件级设置，不和单条提醒配置混在一起。")
            .font(.headline)
            .foregroundStyle(.secondary)
        }

        VStack(alignment: .leading, spacing: 12) {
          Text("配置文件路径")
            .font(.title3.weight(.semibold))

          TextField("settings.json 路径", text: $storagePathDraft)
            .textFieldStyle(.roundedBorder)

          HStack(spacing: 10) {
            Button("应用") {
              store.updateStorageFilePath(storagePathDraft)
            }

            Button("恢复默认") {
              storagePathDraft = ReminderStore.defaultStorageFilePath()
              store.updateStorageFilePath(storagePathDraft)
            }
            .buttonStyle(.plain)
          }

          Text(store.storageFileURL.path)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(3)
        }
        .padding(20)
        .background(cardBackground)

        VStack(alignment: .leading, spacing: 12) {
          Text("菜单栏快捷提醒")
            .font(.title3.weight(.semibold))

          Picker("菜单栏提醒", selection: Binding(
            get: { store.menuBarReminderID ?? store.reminders.first?.id ?? UUID() },
            set: { newValue in
              store.selectMenuBarReminder(newValue)
            }
          )) {
            ForEach(store.reminders) { reminder in
              Text(reminder.title).tag(reminder.id)
            }
          }
          .pickerStyle(.menu)
          .frame(width: 260)

          Text("状态栏里的开始、暂停、立即提醒和停止操作会作用在这里选中的那条提醒。")
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(cardBackground)

        VStack(alignment: .leading, spacing: 12) {
          Text("说明")
            .font(.title3.weight(.semibold))
          Text("提醒数据会保存到外部 JSON 文件。切换路径后，软件会立即读取目标文件；如果文件不存在，会在该位置创建默认配置。")
            .foregroundStyle(.secondary)
          Text("提醒内容支持 Markdown，可插入本地图片。建议把图片放在配置文件附近，便于迁移和同步。")
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(cardBackground)
      }
      .padding(24)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private func reminderHeader(_ reminder: ReminderConfig) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(reminder.title)
        .font(.system(size: 30, weight: .bold, design: .rounded))
    }
  }

  private func sessionCard(_ reminder: ReminderConfig) -> some View {
    let state = manager.state(for: reminder.id)

    return VStack(alignment: .leading, spacing: 16) {
      Text("当前状态")
        .font(.title3.weight(.semibold))

      HStack(alignment: .firstTextBaseline, spacing: 16) {
        VStack(alignment: .leading, spacing: 4) {
          Text(state.label)
            .font(.system(size: 28, weight: .bold, design: .rounded))
          Text(statusDescription(for: state))
            .foregroundStyle(.secondary)
        }
        Spacer()
        if state == .running || state == .paused {
          Text(manager.formattedRemaining(for: reminder.id))
            .font(.system(size: 36, weight: .bold, design: .rounded))
            .monospacedDigit()
        }
      }

      HStack(spacing: 12) {
        Button(primaryButtonTitle(for: state)) {
          handlePrimaryAction(for: reminder, state: state)
        }
        .keyboardShortcut(.defaultAction)

        Button("立即提醒") {
          manager.remindNow(reminder)
        }

        Button("停止") {
          manager.stop(reminder)
        }
        .disabled(state == .idle)
      }
    }
    .padding(20)
    .background(cardBackground)
  }

  private func settingsCard(_ reminder: ReminderConfig) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("提醒设置")
        .font(.title3.weight(.semibold))

      VStack(alignment: .leading, spacing: 8) {
        Text("提醒名称")
        TextField("提醒名称", text: binding(for: reminder).title)
          .textFieldStyle(.roundedBorder)
      }

      HStack(spacing: 20) {
        VStack(alignment: .leading, spacing: 10) {
          Text("提醒间隔")
          HStack {
            MinutesInputField(value: binding(for: reminder).intervalMinutes, minimum: 1)
            Text("分钟")
              .foregroundStyle(.secondary)
          }
        }

        VStack(alignment: .leading, spacing: 10) {
          Text("稍后提醒")
          HStack {
            MinutesInputField(value: binding(for: reminder).snoozeMinutes, minimum: 1)
            Text("分钟")
              .foregroundStyle(.secondary)
          }
        }
      }

      VStack(alignment: .leading, spacing: 10) {
        Text("提醒声音")
        HStack(spacing: 12) {
          Picker("提醒声音", selection: binding(for: reminder).soundName) {
            ForEach(ReminderSound.availableNames, id: \.self) { soundName in
              Text(soundName).tag(soundName)
            }
          }
          .pickerStyle(.menu)
          .frame(width: 180)

          Toggle("启用声音", isOn: binding(for: reminder).soundEnabled)

          Button("试听") {
            ReminderSound.play(named: store.selectedReminder?.soundName ?? ReminderSound.defaultName)
          }
        }
      }

      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Text("提醒内容")
          Spacer()
          Button("插入图片") {
            insertImageMarkdown(into: reminder)
          }
        }

        MarkdownEditorSection(
          text: binding(for: reminder).message,
          baseDirectoryURL: store.storageDirectoryURL()
        )
      }
    }
    .padding(20)
    .background(cardBackground)
  }

  private var cardBackground: some View {
    RoundedRectangle(cornerRadius: 20, style: .continuous)
      .fill(Color(nsColor: .windowBackgroundColor))
      .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
  }

  private func binding(for reminder: ReminderConfig) -> Binding<ReminderConfig> {
    Binding(
      get: { store.reminders.first(where: { $0.id == reminder.id }) ?? reminder },
      set: { store.update($0) }
    )
  }

  private func primaryButtonTitle(for state: SessionState) -> String {
    switch state {
    case .idle:
      return "开始本轮"
    case .running:
      return "暂停"
    case .paused:
      return "继续"
    case .alerting:
      return "开始下一轮"
    }
  }

  private func statusDescription(for state: SessionState) -> String {
    switch state {
    case .idle:
      return "当前没有正在运行的提醒。"
    case .running:
      return "倒计时结束后会弹出该提醒。"
    case .paused:
      return "该提醒已暂停，可以随时继续。"
    case .alerting:
      return "当前正在提醒中，可以稍后提醒或直接结束。"
    }
  }

  private func handlePrimaryAction(for reminder: ReminderConfig, state: SessionState) {
    switch state {
    case .idle:
      manager.start(reminder)
    case .running:
      manager.pause(reminder)
    case .paused:
      manager.resume(reminder)
    case .alerting:
      manager.dismissAlertAndRestart(reminder)
    }
  }

  private func insertImageMarkdown(into reminder: ReminderConfig) {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.image]
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.canChooseFiles = true

    guard panel.runModal() == .OK, let url = panel.url else { return }
    var updated = store.reminders.first(where: { $0.id == reminder.id }) ?? reminder
    let markdown = "\n\n![图片](\(url.absoluteString))\n"
    updated.message += markdown
    store.update(updated)
  }
}

struct ReminderListRow: View {
  let reminder: ReminderConfig
  let state: SessionState
  let remainingText: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(alignment: .top, spacing: 12) {
        Image(systemName: "bell.badge")
          .font(.system(size: 18, weight: .semibold))
          .frame(width: 24, height: 24)
          .foregroundStyle(isSelected ? Color.white : Color.accentColor)

        VStack(alignment: .leading, spacing: 4) {
          Text(reminder.title)
            .font(.body.weight(.semibold))
            .foregroundStyle(isSelected ? Color.white : Color.primary)
          Text(state == .running || state == .paused ? "\(state.label) · \(remainingText)" : state.label)
            .font(.caption)
            .foregroundStyle(isSelected ? Color.white.opacity(0.84) : .secondary)
        }

        Spacer()
      }
      .padding(14)
      .background(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .fill(isSelected ? Color.accentColor : Color.clear)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.15), lineWidth: 1)
      )
    }
    .buttonStyle(.plain)
  }
}

struct ModuleTabButton: View {
  let module: HealthModule
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        Image(systemName: module.iconName)
          .font(.system(size: 18, weight: .semibold))
          .frame(width: 24)
        VStack(alignment: .leading, spacing: 2) {
          Text(module.title)
            .font(.body.weight(.semibold))
          Text(module.subtitle)
            .font(.caption)
            .foregroundStyle(isSelected ? Color.white.opacity(0.85) : .secondary)
            .lineLimit(2)
        }
        Spacer()
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 12)
      .frame(maxWidth: .infinity, alignment: .leading)
      .foregroundStyle(isSelected ? Color.white : Color.primary)
      .background(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .fill(isSelected ? Color.accentColor : Color.clear)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.15), lineWidth: 1)
      )
    }
    .buttonStyle(.plain)
    .contentShape(Rectangle())
  }
}

struct MinutesInputField: View {
  @Binding var value: Double
  let minimum: Double
  @State private var draft: String = ""

  var body: some View {
    TextField("", text: $draft)
      .textFieldStyle(.roundedBorder)
      .frame(width: 96)
      .onAppear { draft = normalizedText(for: value) }
      .onSubmit { commit() }
      .onChange(of: value) { newValue in
        let normalized = normalizedText(for: newValue)
        if draft != normalized {
          draft = normalized
        }
      }
      .onChange(of: draft) { newValue in
        guard !newValue.isEmpty, let parsed = Double(newValue), parsed >= minimum else { return }
        value = parsed
      }
  }

  private func commit() {
    guard let parsed = Double(draft), parsed >= minimum else {
      draft = normalizedText(for: max(value, minimum))
      value = max(value, minimum)
      return
    }
    value = parsed
    draft = normalizedText(for: parsed)
  }

  private func normalizedText(for number: Double) -> String {
    number.rounded() == number ? String(Int(number)) : String(format: "%.1f", number)
  }
}

struct MarkdownEditorSection: View {
  @Binding var text: String
  let baseDirectoryURL: URL

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .top, spacing: 16) {
        TextEditor(text: $text)
          .font(.body)
          .frame(minHeight: 220)
          .padding(8)
          .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
              .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
          )

        MarkdownPreview(markdown: text, baseDirectoryURL: baseDirectoryURL)
          .frame(minWidth: 300, minHeight: 220)
          .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
              .fill(Color(nsColor: .textBackgroundColor))
          )
          .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
              .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
          )
      }

      Text("左侧编辑 Markdown，右侧实时预览。插入图片后会以 Markdown 图片语法保存到 JSON。")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
}

struct MarkdownPreview: NSViewRepresentable {
  let markdown: String
  let baseDirectoryURL: URL

  func makeNSView(context: Context) -> WKWebView {
    let configuration = WKWebViewConfiguration()
    let webView = WKWebView(frame: .zero, configuration: configuration)
    webView.setValue(false, forKey: "drawsBackground")
    return webView
  }

  func updateNSView(_ webView: WKWebView, context: Context) {
    webView.loadHTMLString(
      MarkdownRenderer.html(from: markdown),
      baseURL: baseDirectoryURL
    )
  }
}

enum MarkdownRenderer {
  static func html(from markdown: String) -> String {
    let body = renderBlocks(markdown)
    return """
    <html>
    <head>
      <meta charset="utf-8">
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; padding: 14px; color: #1f2937; line-height: 1.55; background: transparent; }
        h1, h2, h3 { margin: 0 0 10px 0; }
        p { margin: 0 0 10px 0; }
        ul { margin: 0 0 10px 20px; padding: 0; }
        code { background: #f3f4f6; padding: 2px 6px; border-radius: 6px; }
        img { max-width: 100%; border-radius: 12px; margin: 8px 0; }
        strong { font-weight: 700; }
        em { font-style: italic; }
      </style>
    </head>
    <body>\(body)</body>
    </html>
    """
  }

  private static func renderBlocks(_ markdown: String) -> String {
    let lines = markdown.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
    var html: [String] = []
    var paragraph: [String] = []
    var listItems: [String] = []

    func flushParagraph() {
      guard !paragraph.isEmpty else { return }
      let content = paragraph.joined(separator: "<br>")
      html.append("<p>\(renderInline(content))</p>")
      paragraph.removeAll()
    }

    func flushList() {
      guard !listItems.isEmpty else { return }
      let items = listItems.map { "<li>\(renderInline($0))</li>" }.joined()
      html.append("<ul>\(items)</ul>")
      listItems.removeAll()
    }

    for rawLine in lines {
      let line = rawLine.trimmingCharacters(in: .whitespaces)
      if line.isEmpty {
        flushParagraph()
        flushList()
        continue
      }
      if line.hasPrefix("# ") {
        flushParagraph()
        flushList()
        html.append("<h1>\(renderInline(String(line.dropFirst(2))))</h1>")
        continue
      }
      if line.hasPrefix("## ") {
        flushParagraph()
        flushList()
        html.append("<h2>\(renderInline(String(line.dropFirst(3))))</h2>")
        continue
      }
      if line.hasPrefix("### ") {
        flushParagraph()
        flushList()
        html.append("<h3>\(renderInline(String(line.dropFirst(4))))</h3>")
        continue
      }
      if line.hasPrefix("- ") {
        flushParagraph()
        listItems.append(String(line.dropFirst(2)))
        continue
      }
      paragraph.append(line)
    }

    flushParagraph()
    flushList()
    return html.joined()
  }

  private static func renderInline(_ source: String) -> String {
    var text = escapeHTML(source)
    text = replace(pattern: #"\!\[(.*?)\]\((.*?)\)"#, in: text) { matches in
      let alt = matches[1]
      let src = matches[2]
      return "<img src=\"\(src)\" alt=\"\(alt)\">"
    }
    text = replace(pattern: #"\*\*(.*?)\*\*"#, in: text) { matches in
      "<strong>\(matches[1])</strong>"
    }
    text = replace(pattern: #"`(.*?)`"#, in: text) { matches in
      "<code>\(matches[1])</code>"
    }
    text = replace(pattern: #"(?<!\*)\*(?!\*)(.*?)(?<!\*)\*(?!\*)"#, in: text) { matches in
      "<em>\(matches[1])</em>"
    }
    return text
  }

  private static func escapeHTML(_ text: String) -> String {
    text
      .replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
      .replacingOccurrences(of: "\"", with: "&quot;")
  }

  private static func replace(
    pattern: String,
    in text: String,
    transform: ([String]) -> String
  ) -> String {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
      return text
    }
    let nsText = text as NSString
    let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
    var result = text
    for match in matches.reversed() {
      var groups: [String] = []
      for index in 0..<match.numberOfRanges {
        let range = match.range(at: index)
        groups.append(range.location == NSNotFound ? "" : nsText.substring(with: range))
      }
      if let range = Range(match.range, in: result) {
        result.replaceSubrange(range, with: transform(groups))
      }
    }
    return result
  }
}

struct AlertCardView: View {
  @ObservedObject var manager: ReminderManager
  let reminder: ReminderConfig
  let baseDirectoryURL: URL

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      HStack(spacing: 10) {
        Image(systemName: "bell.badge.fill")
          .font(.system(size: 24, weight: .bold))
          .foregroundStyle(Color(red: 0.82, green: 0.34, blue: 0.30))
        Text(reminder.title)
          .font(.system(size: 28, weight: .bold, design: .rounded))
      }

      MarkdownPreview(markdown: reminder.message, baseDirectoryURL: baseDirectoryURL)
        .frame(height: 150)
        .background(
          RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.white.opacity(0.55))
        )

      HStack(spacing: 14) {
        AlertActionButton(
          title: "开始下一轮",
          icon: "play.fill",
          fillColor: Color(red: 0.23, green: 0.56, blue: 0.94),
          foregroundColor: .white
        ) {
          manager.dismissAlertAndRestart(reminder)
        }

        AlertActionButton(
          title: "稍后提醒",
          icon: "clock.badge",
          fillColor: Color(red: 0.95, green: 0.72, blue: 0.26),
          foregroundColor: Color(red: 0.34, green: 0.22, blue: 0.02)
        ) {
          manager.snooze(reminder)
        }

        AlertActionButton(
          title: "知道了",
          icon: "checkmark.circle.fill",
          fillColor: Color(red: 0.82, green: 0.34, blue: 0.30),
          foregroundColor: .white
        ) {
          manager.stop(reminder)
        }
      }
    }
    .padding(24)
    .frame(width: 460, height: 360, alignment: .topLeading)
    .background(
      LinearGradient(
        colors: [
          Color(red: 0.98, green: 0.96, blue: 0.90),
          Color(red: 0.92, green: 0.96, blue: 0.99)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    )
  }
}

struct AlertActionButton: View {
  let title: String
  let icon: String
  let fillColor: Color
  let foregroundColor: Color
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 10) {
        Image(systemName: icon)
          .font(.system(size: 22, weight: .bold))
        Text(title)
          .font(.system(size: 16, weight: .semibold))
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 88)
      .foregroundStyle(foregroundColor)
      .background(
        RoundedRectangle(cornerRadius: 18, style: .continuous)
          .fill(fillColor)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 18, style: .continuous)
          .stroke(Color.white.opacity(0.18), lineWidth: 1)
      )
      .shadow(color: fillColor.opacity(0.22), radius: 10, y: 5)
    }
    .buttonStyle(.plain)
  }
}

MyHealthManagerApp.main()
