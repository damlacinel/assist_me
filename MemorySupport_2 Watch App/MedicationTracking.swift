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
struct BeaconData: Identifiable {
    let id: UUID
    let name: String
    let rssi: Int
    let accelerometerValue: UInt8?
}

// MARK: - BeaconConnectorDelegate
protocol BeaconConnectorDelegate: AnyObject {
    func didDiscoverBeacon(_ beacon: BeaconData)
}

// MARK: - BeaconConnector
class BeaconConnector: NSObject, CBCentralManagerDelegate, ObservableObject {
    @Published var beacons: [BeaconData] = []
    
    weak var delegate: BeaconConnectorDelegate?
    private var centralManager: CBCentralManager!
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }
    
    func startScanning() {
        beacons.removeAll()
        centralManager.scanForPeripherals(withServices: nil,
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }
    
    func stopScanning() {
        centralManager.stopScan()
    }
    
    // MARK: - CBCentralManagerDelegate Methods
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScanning()
        } else {
            print("Bluetooth not available or powered off.")
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        // RSSI eşik değeri, örneğin -70 dBm
        let rssiThreshold = -55
        guard RSSI.intValue >= rssiThreshold else {
            // Eğer sinyal gücü çok düşükse, beacon'u eklemiyoruz.
            return
        }
        
        let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        let beaconName = peripheral.name ?? "Unknown Beacon"
        let accelValue: UInt8? = manufacturerData?.first
        
        let beacon = BeaconData(id: peripheral.identifier,
                                name: beaconName,
                                rssi: RSSI.intValue,
                                accelerometerValue: accelValue)
        
        if let index = beacons.firstIndex(where: { $0.id == beacon.id }) {
            beacons[index] = beacon
        } else {
            beacons.append(beacon)
        }
        delegate?.didDiscoverBeacon(beacon)
    }
}

// MARK: - BeaconMapping & MedicationMapping Models
struct BeaconMapping: Identifiable, Codable {
    let id: UUID
    var boxNumber: Int
}

/// MedicationMapping now only contains the scheduled time and assigned box number.
struct MedicationMapping: Identifiable, Codable {
    var id: UUID = UUID()
    var medicationTime: Date
    var assignedBoxNumber: Int
}

// MARK: - GlobalAlert (for global in‑app alerts)
struct GlobalAlert: Identifiable {
    let id = UUID()
    let message: String
}

// MARK: - AppViewModel
class AppViewModel: ObservableObject, BeaconConnectorDelegate {
    @Published var beaconMappings: [BeaconMapping] = [] {
        didSet {
            saveBeaconMappings()
        }
    }
    @Published var medicationMappings: [MedicationMapping] = [] {
        didSet {
            saveMedicationMappings()
        }
    }
    @Published var beaconConnector = BeaconConnector()
    
    // Global alert property for in‑app alerts.
    @Published var globalAlert: GlobalAlert? = nil
    
    // UserDefaults keys
    private let beaconMappingsKey = "BeaconMappingsKey"
    private let medicationMappingsKey = "MedicationMappingsKey"
    
    init() {
        beaconConnector.delegate = self
        loadBeaconMappings()
        loadMedicationMappings()
        requestNotificationAuthorization()
    }
    
    func didDiscoverBeacon(_ beacon: BeaconData) {
        // Additional beacon processing can be added here if needed.
    }
    
    func assignBeacon(_ beacon: BeaconData, toBox boxNumber: Int) {
        let mapping = BeaconMapping(id: beacon.id, boxNumber: boxNumber)
        beaconMappings.append(mapping)
    }
    
    func addMedication(time: Date, box: Int) {
        let medication = MedicationMapping(medicationTime: time, assignedBoxNumber: box)
        medicationMappings.append(medication)
        scheduleNotification(for: medication)
    }
    
    func updateMedication(_ medication: MedicationMapping) {
        if let index = medicationMappings.firstIndex(where: { $0.id == medication.id }) {
            medicationMappings[index] = medication
            scheduleNotification(for: medication)
        }
    }
    
    // MARK: - Persistence for Beacon Mappings
    private func saveBeaconMappings() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(beaconMappings)
            UserDefaults.standard.set(data, forKey: beaconMappingsKey)
            print("Beacon mappings saved.")
        } catch {
            print("Error saving beacon mappings: \(error)")
        }
    }
    
    private func loadBeaconMappings() {
        if let data = UserDefaults.standard.data(forKey: beaconMappingsKey) {
            do {
                let decoder = JSONDecoder()
                let mappings = try decoder.decode([BeaconMapping].self, from: data)
                beaconMappings = mappings
                print("Beacon mappings loaded: \(mappings.count) items.")
            } catch {
                print("Error loading beacon mappings: \(error)")
            }
        } else {
            print("No saved beacon mappings found.")
        }
    }
    
    // MARK: - Persistence for Medication Mappings
    private func saveMedicationMappings() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(medicationMappings)
            UserDefaults.standard.set(data, forKey: medicationMappingsKey)
            print("Medication mappings saved.")
        } catch {
            print("Error saving medication mappings: \(error)")
        }
    }
    
    private func loadMedicationMappings() {
        if let data = UserDefaults.standard.data(forKey: medicationMappingsKey) {
            do {
                let decoder = JSONDecoder()
                let mappings = try decoder.decode([MedicationMapping].self, from: data)
                medicationMappings = mappings
                print("Medication mappings loaded: \(mappings.count) items.")
            } catch {
                print("Error loading medication mappings: \(error)")
            }
        } else {
            print("No saved medication mappings found.")
        }
    }
    
    // MARK: - Notification Integration
    func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else {
                print("Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
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
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Notification scheduled for Box \(medication.assignedBoxNumber)")
            }
        }
    }
    
    func scheduleWrongBoxNotification(for medication: MedicationMapping, wrongBox: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Wrong Box Alert"
        content.body = "You opened Box \(wrongBox), but your medication is assigned to Box \(medication.assignedBoxNumber)."
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "wrongBox-\(medication.id.uuidString)",
                                            content: content,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling wrong box notification: \(error)")
            } else {
                print("Wrong box notification scheduled for Box \(medication.assignedBoxNumber)")
            }
        }
    }
    
    // Trigger a global alert to be shown on the intro screen.
    func triggerGlobalAlert(message: String) {
        DispatchQueue.main.async {
            self.globalAlert = GlobalAlert(message: message)
        }
    }
}

// MARK: - MedicationIntroView
struct MedicationIntroView: View {
    @StateObject private var viewModel = AppViewModel()
    @State private var showHelp: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    Text("Medication Tracking")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    HStack {
                        
                        Button(action: {
                            showHelp = true
                        }) {
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
                    .sheet(isPresented: $showHelp) {
                        MedicationHelpView()
                    }
                    
                    NavigationLink("Add Medication") {
                        AddMedicationView()
                            .environmentObject(viewModel)
                    }
                    .buttonStyle(MultipleChoiceButtonStyle())
                    
                    NavigationLink("View Schedule") {
                        ViewScheduleView()
                            .environmentObject(viewModel)
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
                .onAppear {
                    viewModel.beaconConnector.startScanning()
                }
                .onDisappear {
                    viewModel.beaconConnector.stopScanning()
                }
            }
            // Global alert shown on the intro screen.
            .alert(item: $viewModel.globalAlert) { alert in
                Alert(title: Text("Alert"),
                      message: Text(alert.message),
                      dismissButton: .default(Text("OK"), action: {
                    viewModel.globalAlert = nil
                }))
            }
        }
    }
}

// MARK: - AddMedicationView
struct AddMedicationView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    
    // A simple model for a single medication schedule entry.
    struct MedicationSchedule: Identifiable {
        var id = UUID()
        var time: Date
        var box: Int
    }
    
    // Start with one default schedule.
    @State private var medicationSchedules: [MedicationSchedule] = [
        MedicationSchedule(time: Date(), box: 1)
    ]
    
    // Compute available boxes for a given schedule entry.
    private func availableBoxes(for schedule: MedicationSchedule) -> [Int] {
        // Get box numbers already assigned in saved medications.
        let usedBoxesFromMappings = Set(viewModel.medicationMappings.map { $0.assignedBoxNumber })
        // Get box numbers used in the new entries (except for the current one).
        let usedBoxesFromSchedules = Set(medicationSchedules.filter { $0.id != schedule.id }.map { $0.box })
        
        let allBoxes = Array(1...10)
        // Filter out boxes that are used either in saved mappings or in other new entries.
        var available = allBoxes.filter { !usedBoxesFromMappings.contains($0) && !usedBoxesFromSchedules.contains($0) }
        
        // Always include the current schedule’s box, so the user’s current selection remains available.
        if !available.contains(schedule.box) {
            available.append(schedule.box)
        }
        return available.sorted()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Enter one or more medication times and select the corresponding box number for each. If you want to add another time, tap the plus button. To remove an entry, tap the minus button.")
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
                                Text("No available boxes")
                                    .foregroundColor(.red)
                            } else {
                                Picker("", selection: $schedule.box) {
                                    ForEach(boxes, id: \.self) { num in
                                        Text("Box \(num)")
                                            .font(.system(size: 16))
                                            .tag(num)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 65, height: 60)
                            }
                        }
                        
                        if medicationSchedules.count > 1 {
                            Button(action: {
                                if let index = medicationSchedules.firstIndex(where: { $0.id == schedule.id }) {
                                    medicationSchedules.remove(at: index)
                                }
                            }) {
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
                
                Button(action: {
                    medicationSchedules.append(MedicationSchedule(time: Date(), box: 1))
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 24))
                        Text("Add another time")
                            .foregroundColor(.white)
                            .font(.system(size: 18))
                    }
                }
                .padding(.horizontal)
                
                Button("Save") {
                    for schedule in medicationSchedules {
                        viewModel.addMedication(time: schedule.time, box: schedule.box)
                    }
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
/// A choice screen that shows two buttons:
/// - "Assign Now": Navigates to the assignment interface.
/// - "See Assignments": Shows an overview of the already assigned beacons with an explanation.
struct BeaconAssignmentChoiceView: View {
    @StateObject private var viewModel = AppViewModel()
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    NavigationLink("Assign Now") {
                        BeaconAssignmentView()
                            .environmentObject(viewModel)
                    }
                    .buttonStyle(MultipleChoiceButtonStyle())
                    
                    NavigationLink("See Assignments") {
                        BeaconAssignmentsOverviewView()
                            .environmentObject(viewModel)
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
/// Displays a list of detected beacons with a wheel picker for each,
/// allowing the user to assign each beacon to a box.
/// Only available options exclude boxes already assigned (unless "None").
struct BeaconAssignmentView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedAssignments: [UUID: String] = [:]
    
    // All possible assignment options.
    private var allOptions: [String] {
        var options = ["None"]
        options.append(contentsOf: (1...10).map { "Box \($0)" })
        return options
    }
    
    // Returns available options for a specific beacon.
    private func availableOptions(for beacon: BeaconData) -> [String] {
        // Get current selections from other beacons.
        let currentSelections = selectedAssignments.filter { $0.key != beacon.id }.map { $0.value }
        // Get persistent assignments from viewModel.
        let persistentAssignments = viewModel.beaconMappings.filter { $0.id != beacon.id }
            .map { "Box \($0.boxNumber)" }
        let usedOptions = Set(currentSelections + persistentAssignments)
        
        // Always include "None" and the current beacon’s selection.
        let currentSelection = selectedAssignments[beacon.id] ?? "None"
        var options = ["None"]
        for i in 1...10 {
            let option = "Box \(i)"
            if !usedOptions.contains(option) || option == currentSelection {
                options.append(option)
            }
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
                
                Text("Select a box for each unassigned beacon. When a beacon is assigned to a box, that box becomes reserved and won't appear for others. If you change the assignment back to 'None', that box becomes available again.")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal)
                
                // Only show beacons that are not yet assigned.
                let unassignedBeacons = viewModel.beaconConnector.beacons.filter { beacon in
                    viewModel.beaconMappings.first(where: { $0.id == beacon.id }) == nil
                }
                
                if unassignedBeacons.isEmpty {
                    Text("No unassigned beacons found.")
                        .foregroundColor(.white)
                        .padding()
                } else {
                    ForEach(unassignedBeacons) { beacon in
                        let binding = Binding<String>(
                            get: { selectedAssignments[beacon.id] ?? "None" },
                            set: { newValue in selectedAssignments[beacon.id] = newValue }
                        )
                        BeaconAssignmentRowView(beacon: beacon,
                                                availableOptions: availableOptions(for: beacon),
                                                selectedAssignment: binding)
                    }
                }
                
                Button("Assign") {
                    for beacon in unassignedBeacons {
                        let assignment = selectedAssignments[beacon.id] ?? "None"
                        if assignment != "None" {
                            if let boxNumber = Int(assignment.replacingOccurrences(of: "Box ", with: "")) {
                                viewModel.assignBeacon(beacon, toBox: boxNumber)
                            }
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
/// A subview for displaying a single beacon's assignment.
struct BeaconAssignmentRowView: View {
    let beacon: BeaconData
    let availableOptions: [String]
    @Binding var selectedAssignment: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                // Show beacon name if available, otherwise show the first 8 characters of its UUID.
                Text(beacon.name == "Unknown Beacon" ? String(beacon.id.uuidString.prefix(8)) : beacon.name)
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
/// An overview screen showing the currently assigned beacons.
struct BeaconAssignmentsOverviewView: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("Current Assignments")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.top)
                
                Text("When you delete an assigned beacon, its mapping is removed—freeing that box number for re-assignment. The beacon gets then added back to 'Assign Now!'.")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                Text("Each beacon is named by the first 8 digits of its UUID.")
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
                                        Button(action: {
                                            viewModel.deleteMapping(mapping)
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
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
struct ViewScheduleView: View {
    @EnvironmentObject var viewModel: AppViewModel
    private let sensorThreshold: UInt8 = 128
    @State private var currentTime: Date = Date()
    @State private var showWrongBoxAlert: Bool = false
    @State private var wrongBoxAlertMessage: String = ""
        
    
    // Dictionary storing a persistent status message for each medication row.
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
                        NavigationLink(destination: EditMedicationView(medication: medication)
                                        .environmentObject(viewModel)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Scheduled Time: \(medication.medicationTime, style: .time)")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                
                                Text("Box Number: \(medication.assignedBoxNumber)")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                
                                // Attempt to find a matching beacon for this medication’s box.
                                if let beacon = viewModel.beaconConnector.beacons.first(where: { b in
                                    if let mapping = viewModel.beaconMappings.first(where: { $0.id == b.id }) {
                                        return mapping.boxNumber == medication.assignedBoxNumber
                                    }
                                    return false
                                }) {
                                    let isOpened = (beacon.accelerometerValue ?? 0) > sensorThreshold
                                    let coverState = isOpened ? "Opened" : "Closed"
                                    Text("Box \(medication.assignedBoxNumber) Cover: \(coverState)")
                                        .foregroundColor(isOpened ? .green : .red)
                                        .font(.system(size: 16))
                                    
                                    if currentTime >= medication.medicationTime, !isOpened {
                                        let timeDiff = currentTime.timeIntervalSince(medication.medicationTime)
                                        if timeDiff < 60 {
                                            // Time for medication
                                            Text("Time for medication!")
                                                .foregroundColor(.yellow)
                                                .font(.system(size: 18))
                                                .onAppear {
                                                    medicationStatus[medication.id] = "Time for medication!"
                                                    viewModel.triggerGlobalAlert(message: "Time for medication! Please take your medication from Box \(medication.assignedBoxNumber).")
                                                }
                                        } else {
                                            // Late
                                            Text("You are late for your medication!")
                                                .foregroundColor(.red)
                                                .font(.system(size: 18))
                                                .onAppear {
                                                    medicationStatus[medication.id] = "You are late for your medication!"
                                                    viewModel.triggerGlobalAlert(message: "You are late for your medication! Please take your medication from Box \(medication.assignedBoxNumber) as soon as possible.")
                                                }
                                        }
                                    }
                                    // If the box is open or it’s before medication time, no inline text is shown here.
                                    
                                } else {
                                    // If no beacon data is found, fallback to the stored status if it exists,
                                    // otherwise a generic message.
                                    if let status = medicationStatus[medication.id] {
                                        Text(status)
                                            .foregroundColor(.red)
                                            .font(.system(size: 18))
                                    } else {
                                        Text("Scheduled for Box \(medication.assignedBoxNumber)")
                                            .foregroundColor(.white)
                                            .font(.footnote)
                                    }
                                }
                            }
                        }
                        .buttonStyle(MultipleChoiceButtonStyle())
                        
                        // Trash button to delete medication
                        Button(action: {
                            viewModel.deleteMedication(medication)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .font(.system(size: 20))
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
            Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                currentTime = Date()
            }
        }
    }

    
    private func checkForWrongBox(for medication: MedicationMapping) {
        for beacon in viewModel.beaconConnector.beacons {
            let isOpened = (beacon.accelerometerValue ?? 0) > sensorThreshold
            if isOpened {
                if let mapping = viewModel.beaconMappings.first(where: { $0.id == beacon.id }) {
                    if mapping.boxNumber != medication.assignedBoxNumber {
                        showWrongBoxAlert = true
                        wrongBoxAlertMessage = "Wrong box opened! Medication is assigned to Box \(medication.assignedBoxNumber), but Box \(mapping.boxNumber) is open."
                        viewModel.scheduleWrongBoxNotification(for: medication, wrongBox: mapping.boxNumber)
                        viewModel.triggerGlobalAlert(message: "Wrong box opened! Medication is assigned to Box \(medication.assignedBoxNumber), but Box \(mapping.boxNumber) is open.")
                    }
                }
            }
        }
    }
    
    private func checkAllWrongBoxes() {
        for medication in viewModel.medicationMappings {
            if currentTime >= medication.medicationTime {
                checkForWrongBox(for: medication)
            }
        }
    }
}

// MARK: - EditMedicationView
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
                    Text("Select Box Number")
                        .foregroundColor(.white)
                    Picker("Box Number", selection: $medication.assignedBoxNumber) {
                        ForEach(1..<11) { num in
                            Text("Box \(num)")
                                .font(.system(size: 16))
                                .tag(num)
                        }
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

//For beacons
extension AppViewModel {
    func deleteMapping(_ mapping: BeaconMapping) {
        if let index = beaconMappings.firstIndex(where: { $0.id == mapping.id }) {
            beaconMappings.remove(at: index)
        }
    }
}

// MARK: - Global Alert Modifier in MedicationIntroView
extension MedicationIntroView {
    func globalAlert() -> some View {
        self.alert(item: Binding(get: {
            viewModel.globalAlert
        }, set: { newValue in
            viewModel.globalAlert = newValue
        })) { alert in
            Alert(title: Text("Alert"),
                  message: Text(alert.message),
                  dismissButton: .default(Text("OK"), action: {
                      viewModel.globalAlert = nil
                  }))
        }
    }
}

//Medication schedule da medication ı silmek için
extension AppViewModel {
    func deleteMedication(_ medication: MedicationMapping) {
        if let index = medicationMappings.firstIndex(where: { $0.id == medication.id }) {
            medicationMappings.remove(at: index)
        }
    }
}
    
// MARK: - MedicationHelpView
struct MedicationHelpView: View {
        @Environment(\.dismiss) var dismiss
        // selectedTopic is used to trigger showing a detail view
        @State private var selectedTopic: Int? = nil

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Help")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // Help topics list
                    ForEach(1...3, id: \.self) { topic in
                        Button(action: {
                            selectedTopic = topic
                        }) {
                            HStack {
                                Text("\(topic).")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                Text(helpTitle(for: topic))
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(8)
                        }
                    }
                    .buttonStyle(MultipleChoiceButtonStyle())
                    
                    // A Done button to dismiss the help view
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(ADStandardButtonStyle())
                    
                    Spacer()
                }
                .padding()
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            // Present detail view as a sheet when a topic is selected.
            .sheet(item: $selectedTopic) { topic in
                MedicationHelpDetailView(topic: topic)
            }
        }
        
        func helpTitle(for topic: Int) -> String {
            switch topic {
            case 1:
                return "How to Add Medication"
            case 2:
                return "How to View Schedule"
            case 3:
                return "How to Assign Beacons"
            default:
                return ""
            }
        }
    }

    // MARK: - MedicationHelpDetailView
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
                    
                    Button("Close") {
                        dismiss()
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                }
                .padding()
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
        
        func detailText(for topic: Int) -> String {
            switch topic {
            case 1:
                return "To add medication, tap 'Add Medication' on the main screen. Then select the medication time and choose an available box number. Each box holds only one medication. To add another time to that box please click on the '+' button."
            case 2:
                return "The 'View Schedule' screen shows all your medication times and the box numbers. It will indicate if it's time for your medication and whether the corresponding box is open or closed. You can delete any entry by clicking on the red trash sign on the button."
            case 3:
                return "In 'Beacon Assignment', you assign each detected beacon to a box. Once a beacon is assigned, that box is reserved and won’t appear as an option for others. If you delete an assignment or change it to 'None', the box becomes available again. To correctly connect to your beacon please check the UUID shown by your beacon. You can gladly take help from your caregiver."
            default:
                return ""
            }
        }
    }

extension Int: Identifiable {
    public var id: Int { self }
}

// MARK: - Previews
struct MedicationIntroView_Previews: PreviewProvider {
    static var previews: some View {
        MedicationIntroView()
    }
}

