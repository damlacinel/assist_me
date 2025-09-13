//
//  MedicationTracking.swift
//  Memory Support
//
//  Created by Damla Cinel on 17.03.25.
//

import SwiftUI
import CoreBluetooth
import Foundation
import UserNotifications

// MARK: - BeaconData Model
// Represents a detected beacon with optional accelerometer byte.
struct BeaconData: Identifiable {
    let id: UUID
    let name: String
    let rssi: Int
    let accelerometerValue: UInt8?
}

// MARK: - BeaconConnectorDelegate
// Delegate for receiving newly discovered beacons.
protocol BeaconConnectorDelegate: AnyObject {
    func didDiscoverBeacon(_ beacon: BeaconData)
}

// MARK: - BeaconConnector
// Handles Bluetooth scanning and publishes discovered beacons.
class BeaconConnector: NSObject, CBCentralManagerDelegate, ObservableObject {
    @Published var beacons: [BeaconData] = []
    weak var delegate: BeaconConnectorDelegate?
    private var centralManager: CBCentralManager!
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }
    
    // Starts scanning and clears previous results.
    func startScanning() {
        beacons.removeAll()
        centralManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
    }
    
    // Stops scanning
    func stopScanning() {
        centralManager.stopScan()
    }
    
    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScanning()
        } else {
            // print("Bluetooth not available or powered off.")
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        // Filter out weak signals
        let rssiThreshold = -55
        guard RSSI.intValue >= rssiThreshold else { return }
        
        // Manufacturer data first byte used as a simple accel indicator
        let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        let accelValue: UInt8? = manufacturerData?.first
        
        let beacon = BeaconData(
            id: peripheral.identifier,
            name: peripheral.name ?? "Unknown Beacon",
            rssi: RSSI.intValue,
            accelerometerValue: accelValue
        )
        
        if let index = beacons.firstIndex(where: { $0.id == beacon.id }) {
            beacons[index] = beacon
        } else {
            beacons.append(beacon)
        }
        delegate?.didDiscoverBeacon(beacon)
    }
}

// MARK: - Mapping Models
//Links a beacon UUID to a medication box number.
struct BeaconMapping: Identifiable, Codable {
    let id: UUID
    var boxNumber: Int
}

// Medication entry with time and assigned box.
struct MedicationMapping: Identifiable, Codable {
    var id: UUID = UUID()
    var medicationTime: Date
    var assignedBoxNumber: Int
}

// MARK: - Global Alert
// Simple global in-app alert payload.
struct GlobalAlert: Identifiable {
    let id = UUID()
    let message: String
}

// MARK: - AppViewModel
// Central ViewModel for mappings, notifications, scanning and alerts.
class AppViewModel: ObservableObject, BeaconConnectorDelegate {
    @Published var beaconMappings: [BeaconMapping] = [] { didSet { saveBeaconMappings() } }
    @Published var medicationMappings: [MedicationMapping] = [] { didSet { saveMedicationMappings() } }
    @Published var beaconConnector = BeaconConnector()
    @Published var globalAlert: GlobalAlert? = nil
    
    private let beaconMappingsKey = "BeaconMappingsKey"
    private let medicationMappingsKey = "MedicationMappingsKey"
    
    init() {
        beaconConnector.delegate = self
        loadBeaconMappings()
        loadMedicationMappings()
        requestNotificationAuthorization()
    }
    
    func didDiscoverBeacon(_ beacon: BeaconData) {
        //optional
    }
        
    // Persist a link from beacon to box.
    func assignBeacon(_ beacon: BeaconData, toBox boxNumber: Int) {
        let mapping = BeaconMapping(id: beacon.id, boxNumber: boxNumber)
        beaconMappings.append(mapping)
    }
    
    // Add medication time and schedule a local notification.
    func addMedication(time: Date, box: Int) {
        let medication = MedicationMapping(medicationTime: time, assignedBoxNumber: box)
        medicationMappings.append(medication)
        scheduleNotification(for: medication)
    }
    
    // Update an existing medication schedule and re-schedule its notification.
    func updateMedication(_ medication: MedicationMapping) {
        if let index = medicationMappings.firstIndex(where: { $0.id == medication.id }) {
            medicationMappings[index] = medication
            scheduleNotification(for: medication)
        }
    }
    
    // MARK: - Persistence
    private func saveBeaconMappings() {
        do {
            let data = try JSONEncoder().encode(beaconMappings)
            UserDefaults.standard.set(data, forKey: beaconMappingsKey)
           // print("Beacon mappings saved.")
        } catch {
          //  print("Error saving beacon mappings: \(error)")
        }
    }
    
    private func loadBeaconMappings() {
        guard let data = UserDefaults.standard.data(forKey: beaconMappingsKey) else { return }
        do {
            beaconMappings = try JSONDecoder().decode([BeaconMapping].self, from: data)
          //  print("Beacon mappings loaded: \(beaconMappings.count) items.")
        } catch {
         //   print("Error loading beacon mappings: \(error)")
        }
    }
    
    private func saveMedicationMappings() {
        do {
            let data = try JSONEncoder().encode(medicationMappings)
            UserDefaults.standard.set(data, forKey: medicationMappingsKey)
          //  print("Medication mappings saved.")
        } catch {
          //  print("Error saving medication mappings: \(error)")
        }
    }
    
    private func loadMedicationMappings() {
        guard let data = UserDefaults.standard.data(forKey: medicationMappingsKey) else { return }
        do {
            medicationMappings = try JSONDecoder().decode([MedicationMapping].self, from: data)
         //   print("Medication mappings loaded: \(medicationMappings.count) items.")
        } catch {
        //    print("Error loading medication mappings: \(error)")
        }
    }
    
    // MARK: - Local Notifications
    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { granted, error in
                if granted {
               //     print("Notification permission granted.")
                } else {
                //    print("Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
    }
    
    func scheduleNotification(for medication: MedicationMapping) {
        let content = UNMutableNotificationContent()
        content.title = "Medication Reminder"
        content.body = "Time to take your medication from Box \(medication.assignedBoxNumber)."
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute],
                                                          from: medication.medicationTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: medication.id.uuidString,
                                            content: content,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            error == nil
            ? print("Notification scheduled for Box \(medication.assignedBoxNumber)")
            : print("Error scheduling notification: \(error!.localizedDescription)")
        }
    }
    
    // Immediate notification when a wrong box appears opened at a scheduled time.
    func scheduleWrongBoxNotification(for medication: MedicationMapping, wrongBox: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Wrong Box Alert"
        content.body = "You opened Box \(wrongBox), but your medication is in Box \(medication.assignedBoxNumber)."
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(identifier: "wrongBox-\(medication.id.uuidString)",
                                            content: content,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            error == nil
            ? print("Wrong box notification scheduled.")
            : print("Error scheduling wrong box notification: \(error!.localizedDescription)")
        }
    }
    
    // Shows a global in-app alert banner.
    func triggerGlobalAlert(message: String) {
        DispatchQueue.main.async { self.globalAlert = GlobalAlert(message: message) }
    }
}

// MARK: - MedicationIntroView
// Entry screen for Medication Tracking module.
struct MedicationIntroView: View {
    @StateObject private var viewModel = AppViewModel()
    @State private var showHelp = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    Text("Medication Tracking")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    HStack {
                        Button(action: { showHelp = true }) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: "h.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.white)
                                )
                        }
                        .buttonStyle(ADStandardButtonStyle())
                    }
                    .padding(.trailing)
                    .sheet(isPresented: $showHelp) { MedicationHelpView() }
                    
                    NavigationLink("Add Medication") {
                        AddMedicationView().environmentObject(viewModel)
                    }
                    .buttonStyle(MultipleChoiceButtonStyle())
                    
                    NavigationLink("View Schedule") {
                        ViewScheduleView().environmentObject(viewModel)
                    }
                    .buttonStyle(MultipleChoiceButtonStyle())
                    
                    NavigationLink("Beacon Assignment") {
                        BeaconAssignmentChoiceView()
                            .environmentObject(viewModel)
                    }
                    .buttonStyle(MultipleChoiceButtonStyle())
                    
                    Spacer()
                }
                .padding()
                .background(Color.black.edgesIgnoringSafeArea(.all))
                .onAppear { viewModel.beaconConnector.startScanning() }
                .onDisappear { viewModel.beaconConnector.stopScanning() }
            }
            // Global one-shot in-app alert
            .alert(item: $viewModel.globalAlert) { alert in
                Alert(title: Text("Alert"),
                      message: Text(alert.message),
                      dismissButton: .default(Text("OK")) { viewModel.globalAlert = nil })
            }
        }
    }
}

// MARK: - AddMedicationView
// Adds one or more medication times with associated box numbers.
struct AddMedicationView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    
    // Local schedule row model for staged entries.
    struct MedicationSchedule: Identifiable {
        var id = UUID()
        var time: Date
        var box: Int
    }
    
    @State private var medicationSchedules: [MedicationSchedule] = [
        MedicationSchedule(time: Date(), box: 1)
    ]
    
    // Available boxes excluding those already taken by saved mappings and other staged entries.
    private func availableBoxes(for schedule: MedicationSchedule) -> [Int] {
        let usedBoxesSaved = Set(viewModel.medicationMappings.map { $0.assignedBoxNumber })
        let usedBoxesDraft = Set(medicationSchedules.filter { $0.id != schedule.id }.map { $0.box })
        let allBoxes = Array(1...10)
        
        var available = allBoxes.filter { !usedBoxesSaved.contains($0) && !usedBoxesDraft.contains($0) }
        if !available.contains(schedule.box) { available.append(schedule.box) }
        return available.sorted()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Enter one or more medication times and select the corresponding box number for each. Use + to add, − to remove.")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                ForEach($medicationSchedules) { $schedule in
                    HStack(spacing: 5) {
                        DatePicker("", selection: $schedule.time, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .frame(width: 110)
                        
                        VStack {
                            Text("Box")
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                            let boxes = availableBoxes(for: schedule)
                            if boxes.isEmpty {
                                Text("No available boxes").foregroundColor(.red)
                            } else {
                                Picker("", selection: $schedule.box) {
                                    ForEach(boxes, id: \.self) { num in
                                        Text("Box \(num)").tag(num)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 65, height: 60)
                            }
                        }
                        
                        if medicationSchedules.count > 1 {
                            Button {
                                if let idx = medicationSchedules.firstIndex(where: { $0.id == schedule.id }) {
                                    medicationSchedules.remove(at: idx)
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 24))
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.8))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                Button {
                    medicationSchedules.append(.init(time: Date(), box: 1))
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill").foregroundColor(.green).font(.system(size: 24))
                        Text("Add another time").foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
                
                Button("Save") {
                    medicationSchedules.forEach { viewModel.addMedication(time: $0.time, box: $0.box) }
                    dismiss()
                }
                .buttonStyle(MultipleChoiceButtonStyle())
                .padding(.top, 20)
                
                Spacer()
            }
            .padding()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

// MARK: - BeaconAssignmentChoiceView
// Allows user to either assign beacons now or review existing assignments.
struct BeaconAssignmentChoiceView: View {
    @StateObject private var viewModel = AppViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    NavigationLink("Assign Now") {
                        BeaconAssignmentView().environmentObject(viewModel)
                    }
                    .buttonStyle(MultipleChoiceButtonStyle())
                    
                    NavigationLink("See Assignments") {
                        BeaconAssignmentsOverviewView().environmentObject(viewModel)
                    }
                    .buttonStyle(MultipleChoiceButtonStyle())
                }
                .padding()
                .background(Color.black.edgesIgnoringSafeArea(.all))
            }
        }
    }
}

// MARK: - BeaconAssignmentView
// Shows unassigned beacons and lets user assign each to a unique box.
struct BeaconAssignmentView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedAssignments: [UUID: String] = [:]
    
    private var allOptions: [String] {
        ["None"] + (1...10).map { "Box \($0)" }
    }
    
    // Options excluding boxes used by other selections or existing mappings (except current).
    private func availableOptions(for beacon: BeaconData) -> [String] {
        let currentSelections = selectedAssignments.filter { $0.key != beacon.id }.map { $0.value }
        let persistent = viewModel.beaconMappings
            .filter { $0.id != beacon.id }
            .map { "Box \($0.boxNumber)" }
        
        let used = Set(currentSelections + persistent)
        let current = selectedAssignments[beacon.id] ?? "None"
        
        var options = ["None"]
        for i in 1...10 {
            let opt = "Box \(i)"
            if !used.contains(opt) || opt == current { options.append(opt) }
        }
        return options
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Beacon Assignment")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .padding(.top)
                
                Text("Select a box for each unassigned beacon. Assigned boxes are hidden for others until freed.")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal)
                
                let unassigned = viewModel.beaconConnector
                    .beacons
                    .filter { _ in viewModel.beaconMappings.first(where: { $0.id == $0.id }) == nil }
                    .filter { beacon in
                        // Ensure not already mapped
                        viewModel.beaconMappings.first(where: { $0.id == beacon.id }) == nil
                    }
                
                if unassigned.isEmpty {
                    Text("No unassigned beacons found.")
                        .foregroundColor(.white)
                        .padding()
                } else {
                    ForEach(unassigned) { beacon in
                        let binding = Binding<String>(
                            get: { selectedAssignments[beacon.id] ?? "None" },
                            set: { selectedAssignments[beacon.id] = $0 }
                        )
                        BeaconAssignmentRowView(
                            beacon: beacon,
                            availableOptions: availableOptions(for: beacon),
                            selectedAssignment: binding
                        )
                    }
                }
                
                Button("Assign") {
                    for beacon in unassigned {
                        let assignment = selectedAssignments[beacon.id] ?? "None"
                        if assignment != "None",
                           let boxNumber = Int(assignment.replacingOccurrences(of: "Box ", with: "")) {
                            viewModel.assignBeacon(beacon, toBox: boxNumber)
                        }
                    }
                    dismiss()
                }
                .buttonStyle(ADStandardButtonStyle())
                .padding(.top, 20)
            }
            .padding()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

// MARK: - BeaconAssignmentRowView
// Single-row UI for selecting a box for a beacon.
struct BeaconAssignmentRowView: View {
    let beacon: BeaconData
    let availableOptions: [String]
    @Binding var selectedAssignment: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(beacon.name == "Unknown Beacon"
                     ? String(beacon.id.uuidString.prefix(8))
                     : beacon.name)
                    .foregroundColor(.white)
                Text("RSSI: \(beacon.rssi)")
                    .foregroundColor(.white)
                    .font(.system(size: 16))
            }
            Spacer()
            Picker("Assignment", selection: $selectedAssignment) {
                ForEach(availableOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(width: 100)
        }
        .padding()
        .background(Color.blue)
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

// MARK: - BeaconAssignmentsOverviewView
// Displays current beacon→box mappings and allows deleting them.
struct BeaconAssignmentsOverviewView: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("Current Assignments")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.top)
                
                Text("Deleting an assignment frees its box and the beacon appears again under 'Assign Now'.")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                Text("Beacons are shown by the first 8 characters of their UUID if unnamed.")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                ForEach(viewModel.beaconMappings) { mapping in
                    HStack {
                        Text("Beacon \(mapping.id.uuidString.prefix(8))")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Text("Box \(mapping.boxNumber)")
                            .font(.headline)
                            .foregroundColor(.white)
                        Button {
                            viewModel.deleteMapping(mapping)
                        } label: {
                            Image(systemName: "trash").foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            }
            .padding()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

// MARK: - ViewScheduleView
// Shows all medication entries, live beacon/cover state and time-based hints.
struct ViewScheduleView: View {
    @EnvironmentObject var viewModel: AppViewModel
    private let sensorThreshold: UInt8 = 128
    @State private var currentTime = Date()
    
    /// Persistent per-row status (e.g., late).
    @State private var medicationStatus: [UUID: String] = [:]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Medication Schedule")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .padding(.top, 10)
                
                ForEach(viewModel.medicationMappings) { medication in
                    HStack {
                        NavigationLink(
                            destination: EditMedicationView(medication: medication).environmentObject(viewModel)
                        ) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Scheduled Time: \(medication.medicationTime, style: .time)")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                
                                Text("Box Number: \(medication.assignedBoxNumber)")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                
                                // Live beacon status for the box (open/closed)
                                if let beacon = viewModel.beaconConnector.beacons.first(where: { b in
                                    if let map = viewModel.beaconMappings.first(where: { $0.id == b.id }) {
                                        return map.boxNumber == medication.assignedBoxNumber
                                    }
                                    return false
                                }) {
                                    let isOpened = (beacon.accelerometerValue ?? 0) > sensorThreshold
                                    Text("Box \(medication.assignedBoxNumber) Cover: \(isOpened ? "Opened" : "Closed")")
                                        .foregroundColor(isOpened ? .green : .red)
                                        .font(.system(size: 16))
                                    
                                    // Time-based messages
                                    if currentTime >= medication.medicationTime, !isOpened {
                                        let delta = currentTime.timeIntervalSince(medication.medicationTime)
                                        if delta < 60 {
                                            Text("Time for medication!")
                                                .foregroundColor(.yellow)
                                                .font(.system(size: 18))
                                                .onAppear {
                                                    medicationStatus[medication.id] = "Time for medication!"
                                                    viewModel.triggerGlobalAlert(
                                                        message: "Time for medication! Please take it from Box \(medication.assignedBoxNumber)."
                                                    )
                                                }
                                        } else {
                                            Text("You are late for your medication!")
                                                .foregroundColor(.red)
                                                .font(.system(size: 18))
                                                .onAppear {
                                                    medicationStatus[medication.id] = "You are late for your medication!"
                                                    viewModel.triggerGlobalAlert(
                                                        message: "You are late! Please take it from Box \(medication.assignedBoxNumber)."
                                                    )
                                                }
                                        }
                                    }
                                } else {
                                    // Fallback status if no live beacon found
                                    if let status = medicationStatus[medication.id] {
                                        Text(status).foregroundColor(.red).font(.system(size: 18))
                                    } else {
                                        Text("Scheduled for Box \(medication.assignedBoxNumber)")
                                            .foregroundColor(.white)
                                            .font(.footnote)
                                    }
                                }
                            }
                        }
                        .buttonStyle(MultipleChoiceButtonStyle())
                        
                        // Delete row
                        Button { viewModel.deleteMedication(medication) } label: {
                            Image(systemName: "trash").foregroundColor(.red).font(.system(size: 20))
                        }
                        .padding(.leading, 4)
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            }
            .padding()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onAppear {
            // Tick every minute to refresh time-based messages
            Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in currentTime = Date() }
        }
    }
}

// MARK: - EditMedicationView
// Edit a single medication entry (time + box).
struct EditMedicationView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    @State var medication: MedicationMapping
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("Edit Medication")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(.top, 10)
                
                DatePicker("Medication Time", selection: $medication.medicationTime, displayedComponents: .hourAndMinute)
                    .padding(.horizontal)
                
                VStack {
                    Text("Select Box Number").foregroundColor(.white)
                    Picker("Box Number", selection: $medication.assignedBoxNumber) {
                        ForEach(1..<11) { Text("Box \($0)").tag($0) }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 80)
                }
                .padding(.horizontal)
                
                Button("Save") {
                    viewModel.updateMedication(medication)
                    dismiss()
                }
                .buttonStyle(ADStandardButtonStyle())
                
                Spacer()
            }
            .padding()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

// MARK: - AppViewModel Extensions (CRUD helpers)
extension AppViewModel {
    // Remove an existing beacon→box mapping.
    func deleteMapping(_ mapping: BeaconMapping) {
        if let index = beaconMappings.firstIndex(where: { $0.id == mapping.id }) {
            beaconMappings.remove(at: index)
        }
    }
    
    /// Delete a medication schedule.
    func deleteMedication(_ medication: MedicationMapping) {
        if let index = medicationMappings.firstIndex(where: { $0.id == medication.id }) {
            medicationMappings.remove(at: index)
        }
    }
}

// MARK: - MedicationHelpView
// Help hub with topics opening detailed instructions.
struct MedicationHelpView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTopic: Int? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Help")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                ForEach(1...3, id: \.self) { topic in
                    Button { selectedTopic = topic } label: {
                        HStack {
                            Text("\(topic).").font(.headline).foregroundColor(.blue)
                            Text(helpTitle(for: topic)).font(.headline).foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(8)
                    }
                    .buttonStyle(MultipleChoiceButtonStyle())
                }
                
                Button("Done") { dismiss() }
                    .buttonStyle(ADStandardButtonStyle())
                
                Spacer()
            }
            .padding()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .sheet(item: $selectedTopic) { topic in
            MedicationHelpDetailView(topic: topic)
        }
    }
    
    private func helpTitle(for topic: Int) -> String {
        switch topic {
        case 1: return "How to Add Medication"
        case 2: return "How to View Schedule"
        case 3: return "How to Assign Beacons"
        default: return ""
        }
    }
}

// MARK: - MedicationHelpDetailView
// Detail pages for each help topic.
struct MedicationHelpDetailView: View, Identifiable {
    var id: Int { topic }
    let topic: Int
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(detailText(for: topic))
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                
                Button("Close") { dismiss() }
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            .padding()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
    
    private func detailText(for topic: Int) -> String {
        switch topic {
        case 1:
            return """
To add medication, tap 'Add Medication' on the main screen. Select the time and choose an available box number. Each box holds one medication at a time. Use '+' to add more times.
"""
        case 2:
            return """
'View Schedule' shows all medication times and box numbers. It indicates if it's time and whether the box looks opened/closed. Delete an entry with the red trash icon.
"""
        case 3:
            return """
In 'Beacon Assignment', assign detected beacons to boxes. An assigned box becomes unavailable for others until freed. If you delete an assignment or set it to 'None', that box becomes available again.
"""
        default:
            return ""
        }
    }
}

extension Int: Identifiable { public var id: Int { self } }
