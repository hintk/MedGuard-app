import SwiftUI

struct DrugSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [DrugInfo] = []
    @State private var selectedDrug: DrugInfo?
    
    let onSelect: (DrugInfo) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                
                if searchResults.isEmpty && !searchText.isEmpty {
                    emptyState
                } else if searchResults.isEmpty {
                    categoriesGrid
                } else {
                    searchResultsList
                }
            }
            .background(Theme.Colors.background)
            .navigationTitle("搜索药品")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onChange(of: searchText) { newValue in
                performSearch(newValue)
            }
        }
    }
    
    private var searchBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.Colors.secondaryText)
            
            TextField("输入药品名称或通用名", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.Colors.tertiaryText)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
    }
    
    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Spacer()
            Image(systemName: "pills")
                .font(.system(size: 48))
                .foregroundStyle(Theme.Colors.tertiaryText)
            Text("未找到相关药品")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.secondaryText)
            Text("您可以手动输入药品信息")
                .font(Theme.Typography.caption1)
                .foregroundStyle(Theme.Colors.tertiaryText)
            Spacer()
        }
    }
    
    private var categoriesGrid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("常用分类")
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Colors.secondaryText)
                    .padding(.horizontal, Theme.Spacing.md)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Theme.Spacing.sm) {
                    ForEach(DrugDatabase.shared.allCategories, id: \.self) { category in
                        categoryButton(category)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
            .padding(.top, Theme.Spacing.md)
        }
    }
    
    private func categoryButton(_ category: String) -> some View {
        Button {
            searchText = category
        } label: {
            HStack {
                Image(systemName: categoryIcon(category))
                    .font(.system(size: 14))
                Text(category)
                    .font(Theme.Typography.subheadline)
                Spacer()
            }
            .foregroundStyle(Theme.Colors.primaryText)
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
        }
    }
    
    private func categoryIcon(_ category: String) -> String {
        switch category {
        case "心脑血管": return "heart.fill"
        case "降糖药": return "drop.circle.fill"
        case "消化系统": return "pills.circle.fill"
        case "感冒药": return "thermometer.medium"
        case "止咳药": return "lungs.fill"
        case "维生素矿物质": return "sun.max.fill"
        case "镇痛消炎": return "bandage.fill"
        case "抗过敏": return "leaf.fill"
        case "安神助眠": return "moon.zzz.fill"
        default: return "pills.fill"
        }
    }
    
    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.sm) {
                ForEach(searchResults) { drug in
                    DrugSearchResultRow(drug: drug) {
                        onSelect(drug)
                        dismiss()
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, Theme.Spacing.sm)
        }
    }
    
    private func performSearch(_ query: String) {
        if DrugDatabase.shared.allCategories.contains(query) {
            searchResults = DrugDatabase.shared.drugsByCategory(query)
        } else {
            searchResults = DrugDatabase.shared.search(query)
        }
    }
}

struct DrugSearchResultRow: View {
    let drug: DrugInfo
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.healthBlue.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "pills.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.Colors.healthBlue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(drug.name)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.primaryText)
                    
                    if !drug.genericName.isEmpty && drug.genericName != drug.name {
                        Text(drug.genericName)
                            .font(Theme.Typography.caption1)
                            .foregroundStyle(Theme.Colors.secondaryText)
                    }
                    
                    HStack(spacing: Theme.Spacing.sm) {
                        Text(drug.category)
                            .font(Theme.Typography.caption2)
                            .foregroundStyle(Theme.Colors.healthBlue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.Colors.healthBlue.opacity(0.1))
                            .clipShape(Capsule())
                        
                        if !drug.manufacturer.isEmpty {
                            Text(drug.manufacturer)
                                .font(Theme.Typography.caption2)
                                .foregroundStyle(Theme.Colors.tertiaryText)
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.tertiaryText)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DrugSearchSheet { drug in
        print("Selected: \(drug.name)")
    }
}
