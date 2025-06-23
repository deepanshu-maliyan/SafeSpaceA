import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var selectedType: ObjectType?
    
    var filteredObjects: [ObjectType] {
        if searchText.isEmpty {
            return ObjectType.allCases
        } else {
            return ObjectType.allCases.filter { 
                $0.rawValue.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter section
                filterSection
                
                // Object list
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredObjects, id: \.self) { objectType in
                            LibraryItemView(objectType: objectType)
                                .onTapGesture {
                                    selectedType = objectType
                                }
                        }
                    }
                    .padding()
                }
                .background(AppColors.background)
            }
            .navigationTitle("Equipment Library")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search equipment")
            .sheet(item: $selectedType) { type in
                ObjectDetailView(objectType: type)
            }
        }
    }
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ObjectType.allCases, id: \.self) { type in
                    Button(action: {
                        withAnimation {
                            if selectedType == type {
                                selectedType = nil
                            } else {
                                selectedType = type
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: type.icon)
                                .font(.system(size: 14))
                            
                            Text(type.rawValue)
                                .font(.caption)
                        }
                        .foregroundColor(selectedType == type ? .white : type.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedType == type ? type.color : type.color.opacity(0.1))
                        )
                    }
                }
            }
            .padding()
        }
        .background(AppColors.background)
    }
}

struct LibraryItemView: View {
    var objectType: ObjectType
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(objectType.color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: objectType.icon)
                    .font(.system(size: 24))
                    .foregroundColor(objectType.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(objectType.rawValue)
                    .font(.headline)
                    .foregroundColor(AppColors.text)
                
                Text(objectType.description)
                    .font(.caption)
                    .foregroundColor(AppColors.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(AppColors.secondaryText)
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(12)
    }
}

struct ObjectDetailView: View {
    var objectType: ObjectType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Object icon
                    ZStack {
                        Circle()
                            .fill(objectType.color.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: objectType.icon)
                            .font(.system(size: 48))
                            .foregroundColor(objectType.color)
                    }
                    
                    // Object details
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Text(objectType.rawValue)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.text)
                            
                            HStack {
                                StatusBadgeView(
                                    status: objectType == .fireExtinguisher || objectType == .oxygenTank ? "Critical" : "Standard",
                                    color: objectType == .fireExtinguisher || objectType == .oxygenTank ? AppColors.secondaryAccent : AppColors.success
                                )
                                
                                StatusBadgeView(
                                    status: "Detectable",
                                    color: AppColors.accent
                                )
                            }
                        }
                        
                        Text(objectType.description)
                            .font(.body)
                            .foregroundColor(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    
                    // Detection metrics
                    VStack(spacing: 12) {
                        Text("Detection Metrics")
                            .font(.headline)
                            .foregroundColor(AppColors.text)
                        
                        HStack {
                            detectionMetricView(
                                title: "Accuracy",
                                value: "92%",
                                icon: "checkmark.seal",
                                color: AppColors.success
                            )
                            
                            Divider()
                                .background(AppColors.secondaryText)
                                .frame(height: 40)
                            
                            detectionMetricView(
                                title: "Speed",
                                value: "35ms",
                                icon: "speedometer",
                                color: AppColors.accent
                            )
                            
                            Divider()
                                .background(AppColors.secondaryText)
                                .frame(height: 40)
                            
                            detectionMetricView(
                                title: "Occlusion",
                                value: "High",
                                icon: "eye",
                                color: AppColors.info
                            )
                        }
                        .padding()
                        .background(AppColors.cardBackground)
                        .cornerRadius(12)
                    }
                    
                    // Location stats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Last Detected")
                            .font(.headline)
                            .foregroundColor(AppColors.text)
                        
                        HStack {
                            Text("Module A, Section 3")
                                .font(.subheadline)
                                .foregroundColor(AppColors.accent)
                            
                            Spacer()
                            
                            Text("12 minutes ago")
                                .font(.caption)
                                .foregroundColor(AppColors.secondaryText)
                        }
                        .padding()
                        .background(AppColors.cardBackground)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .background(AppColors.background)
            .navigationTitle("Object Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
            }
        }
    }
    
    private func detectionMetricView(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 20))
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(AppColors.text)
            
            Text(title)
                .font(.caption)
                .foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    LibraryView()
        .environmentObject(AppState())
} 