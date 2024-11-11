import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            ExerciseListView(exercises: exercises)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}



struct Exercise: Identifiable {
    let id = UUID()
    let name: String
    let target: String
    let description: String
}


let exercises = [
    Exercise(name: "Seated Arm Raises", target: "Arms", description: "Sit upright and raise your arms to shoulder level."),
    Exercise(name: "Arm Circles", target: "Arms", description: "Extend your arms to the side and make small circles."),
    Exercise(name: "Elbow Flexion", target: "Arms", description: "Bend and extend the elbow to exercise the bicep."),
    Exercise(name: "Wrist Flexion and Extension", target: "Arms", description: "Move your wrist up and down to improve flexibility."),
    Exercise(name: "Seated Leg Lifts", target: "Legs", description: "Lift one leg at a time while seated."),
    Exercise(name: "Ankle Rotations", target: "Legs", description: "Rotate your ankles in a circular motion."),
    Exercise(name: "Torso Twists", target: "Core", description: "Twist your torso to the left and right while seated."),
    Exercise(name: "Seated Forward Bends", target: "Core", description: "Bend forward slowly to stretch your back."),Exercise(name: "touching kids", target: "pedophiles", description: "Sit upright and raise your arms to shoulder level and touch all kids nearby.")
]


struct ExerciseListView: View {
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    
    let filters = ["All", "Arms", "Legs", "Core"]
    let exercises: [Exercise]

   
    var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            (selectedFilter == "All" || exercise.target == selectedFilter) &&
            (searchText.isEmpty || exercise.name.localizedCaseInsensitiveContains(searchText))
        }
    }
    
    var body: some View {
        VStack {
            Text("big juicy streak🔥")
            TextField("Search exercises...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .accessibilityLabel("Search for exercises ")

            
            Picker("Target", selection: $selectedFilter) {
                ForEach(filters, id: \.self) { filter in
                    Text(filter)
                        .tag(filter)
                        .accessibilityLabel("Filter by \(filter)")
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            
            List(filteredExercises) { exercise in
                VStack(alignment: .leading) {
                    Text(exercise.name)
                        .font(.headline)
                    Text(exercise.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("moveAbility")
    }
}
