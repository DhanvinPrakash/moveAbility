import SwiftUI
import CoreMotion
import UIKit

struct ContentView: View {
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    @StateObject private var streakManager = StreakManager()
    
    let filters = ["All", "Arms", "Legs", "Core"]
    let exercises: [Exercise] = [
        Exercise(name: "Seated Arm Raises", target: "Arms", description: "Sit upright and raise your arms to shoulder level.", imageName: "SeatedArmRaises", caloriesPerRep: 0.1),
        Exercise(name: "Arm Circles", target: "Arms", description: "Extend your arms to the side and make small circles.", imageName: "ArmCircles", caloriesPerRep: 0.1),
        Exercise(name: "Elbow Flexion", target: "Arms", description: "Bend and extend the elbow to exercise the bicep.", imageName: "ElbowFlexion", caloriesPerRep: 0.1),
        Exercise(name: "Wrist Flexion and Extension", target: "Arms", description: "Move your wrist up and down to improve flexibility.", imageName: "WristFlexion", caloriesPerRep: 0.05),
        Exercise(name: "Seated Leg Lifts", target: "Legs", description: "Lift one leg at a time while seated.", imageName: "SeatedLegLifts", caloriesPerRep: 0.1),
        Exercise(name: "Ankle Rotations", target: "Legs", description: "Rotate your ankles in a circular motion.", imageName: "AnkleRotations", caloriesPerRep: 0.05),
        Exercise(name: "Seated Forward Bends", target: "Core", description: "Bend forward slowly to stretch your back.", imageName: "SeatedForwardBends", caloriesPerRep: 0.05),
        Exercise(name: "Weighted Arm Raises", target: "Arms", description: "Sit upright and raise your arms to shoulder level and stretch them above your head as high as possible.", imageName: "WeightedArmRaises", caloriesPerRep: 0.2)
    ]
    
    var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            (selectedFilter == "All" || exercise.target == selectedFilter) &&
            (searchText.isEmpty || exercise.name.localizedCaseInsensitiveContains(searchText))
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Target", selection: $selectedFilter) {
                    ForEach(filters, id: \.self) { filter in
                        Text(filter).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                List {
                    Text("Streak: \(streakManager.streakCount) day(s) 🔥")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .padding()
                    
                    Section {
                        ForEach(filteredExercises) { exercise in
                            NavigationLink(destination: ExerciseDetailView(exercise: exercise, streakManager: streakManager)) {
                                VStack(alignment: .leading) {
                                    Text(exercise.name).font(.headline)
                                    Text(exercise.description).font(.subheadline).foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
                .searchable(text: $searchText, prompt: "Search exercises")
                
            }
            .navigationTitle("moveAbility")
            .navigationTitle("Streak: \(streakManager.streakCount) day(s) 🔥")
        }
    }
}

struct ExerciseDetailView: View {
    let exercise: Exercise
    @ObservedObject var streakManager: StreakManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(exercise.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Image(exercise.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 250)
                    .cornerRadius(10)
                    .padding()
                
                Text(exercise.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                
                // NavigationLink to ExerciseModeView
                NavigationLink(destination: ExerciseModeView(exercise: exercise)) {
                    Text("Start Exercise Mode")
                        .padding()
                        .frame(width: 300, height: 100)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 3)
                }
                .padding()
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

struct ExerciseModeView: View {
    let exercise: Exercise
    @State private var repCount = 0
    @State private var isInRep = false
    @State private var motionManager = CMMotionManager()
    @State private var isFinishedExercise = false
    
    // Track the presentation of the FinishedExerciseView
    @State private var isExerciseFinished = false
    
    // Navigation: "Go Back Home"
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                
                Spacer()
            }
            .padding()
            
            Text("Exercise Mode")
                .font(.title)
            
            Text("Keep moving! Reps: \(repCount)")
                .font(.title)
                .bold()
            
            Button("Stop Exercise") {
                stopExercise()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding()
        .onAppear {
            startExercise()
        }
        .onDisappear {
            stopExercise() // Ensure we stop accelerometer updates when leaving the mode
        }
        // Present the Finished Exercise View once the exercise is finished
        .sheet(isPresented: $isExerciseFinished) {
            FinishedExerciseView(repCount: $repCount, resetReps: resetReps, caloriesPerRep: exercise.caloriesPerRep)
                .onDisappear {
                    presentationMode.wrappedValue.dismiss() // Dismiss and go back home when sheet disappears
                }
        }
    }
    
    func startExercise() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { data, error in
                guard let data = data else { return }
                
                let angle = calculateAngle(from: data.acceleration)
                
                if angle > 50 && !isInRep {
                    isInRep = true
                    repCount += 1
                    triggerHapticFeedback()
                } else if angle < 30 && isInRep {
                    isInRep = false
                }
            }
        }
    }
    
    func stopExercise() {
        motionManager.stopAccelerometerUpdates()
        isExerciseFinished = true // Show the Finished Exercise View when stopping
    }
    
    func calculateAngle(from acceleration: CMAcceleration) -> Double {
        let angle = atan2(acceleration.y, acceleration.x) * 180 / .pi
        return abs(angle)
    }
    
    func triggerHapticFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func resetReps() {
        repCount = 0
    }
}

struct FinishedExerciseView: View {
    @Binding var repCount: Int
    let resetReps: () -> Void
    let caloriesPerRep: Double
    
    var caloriesBurned: Double {
        // Calculate the total calories burned
        return Double(repCount) * caloriesPerRep
    }
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            
            
            
            Text("Exercise Finished!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            Text("Reps Completed: \(repCount)")
                .font(.title2)
            
            Text("Calories Burned: \(String(format: "%.2f", caloriesBurned)) kcal")
                .font(.title2)
            
            Button("Reset Reps") {
                resetReps()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal)
            
            
            Button(action: {
                presentationMode.wrappedValue.dismiss() // Go back to home view
            }) {
                Text("Go Back Home")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .onDisappear {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

class StreakManager: ObservableObject {
    @Published var streakCount: Int = 0
    @Published var lastActivityDate: Date?
    
    private let streakKey = "streakCount"
    
    init() {
        loadStreak()
    }
    
    func loadStreak() {
        if let savedDate = UserDefaults.standard.object(forKey: "lastActivityDate") as? Date {
            let calendar = Calendar.current
            if calendar.isDateInToday(savedDate) {
                streakCount += 1
            } else {
                streakCount = 1
            }
        }
    }
    
    func resetStreak() {
        streakCount = 0
    }
}

struct Exercise: Identifiable {
    let id = UUID()
    let name: String
    let target: String
    let description: String
    let imageName: String
    let caloriesPerRep: Double
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
