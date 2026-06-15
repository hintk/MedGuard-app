import SwiftUI

struct HomeView: View {
    var body: some View {
        TimelineView(isHomeTimeline: true)
    }
}

#Preview {
    HomeView()
        .environmentObject(MedicationStore())
}
