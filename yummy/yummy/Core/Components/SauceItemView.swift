import SwiftUI

struct SauceItemView: View {
    let formulaId: String
    let sauceIngredients: [SauceIngredient]
    let isCompleted: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 料汁标题和复选框
            HStack {
                Text("料汁")
                    .appStyle(isCompleted ? .subtitle : .cardTitle)
                    .strikethrough(isCompleted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                CuisineCheckboxView(isCompleted: isCompleted, action: onToggle)
                    .frame(width: 32,alignment: .center)
            }
//            .padding()
            .padding(.vertical,8)
//            .padding(.leading,32)
            .background(.backgroundWhite)
            
            // 材料列表
            VStack(spacing: 0) {
                ForEach(Array(sauceIngredients.enumerated()), id: \.offset) { index, ingredient in
                    HStack {
                        // 左侧：材料名称
                        Text(ingredient.name)
                            .appStyle(isCompleted ? .subtitle : .body)
                            .strikethrough(isCompleted)
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // 右侧：用量
                        Text(ingredient.quantity)
                            .appStyle(isCompleted ? .subtitle : .body)
                            .strikethrough(isCompleted)
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
//                    .padding(.horizontal, 48)
                    .padding(.vertical, 8)
                    .background(.backgroundWhite)
                    
                    // 最后一项不显示分隔线
//                    if index < sauceIngredients.count - 1 {
//                        Divider()
//                            .background(.lineFrame)
//                    }
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        SauceItemView(
            formulaId: "1", 
            sauceIngredients: [
                SauceIngredient(name: "生抽", quantity: "适量"),
                SauceIngredient(name: "老抽", quantity: "少许"),
                SauceIngredient(name: "蚝油", quantity: "适量"),
                SauceIngredient(name: "盐", quantity: "适量"),
                SauceIngredient(name: "鸡精", quantity: "适量"),
                SauceIngredient(name: "白糖", quantity: "一勺"),
                SauceIngredient(name: "淀粉", quantity: "一大勺"),
                SauceIngredient(name: "清水", quantity: "少许")
            ],
            isCompleted: true,
            onToggle: {}
        )
    }
    .background(Color.backgroundDefault)
} 
