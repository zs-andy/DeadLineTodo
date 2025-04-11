//
//  SearchTodoViewModifier.swift
//  DeadLineTodo
//
//  Created by Haiyao Zhou on 11/04/2025.
//

import SwiftUI

struct textContentView: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(Color.myBlack)
            .multilineTextAlignment(.leading)
            .bold()
            .font(.system(size: 17))
    }
}

struct textRepeatedTimesView: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(Color.blackGray)
            .bold()
            .font(.system(size: 11))
    }
}

struct textTimeView: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(Color.blackGray)
            .padding(.bottom, 0.5)
            .padding(.horizontal, -3)
            .bold()
            .font(.system(size: 13))
    }
}

struct textEndDateView: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(Color.creamBrown)
            .padding(.bottom, 0.5)
            .padding(.horizontal, -3)
            .bold()
            .font(.system(size: 13))
    }
}

extension View {
    public func textContentStyle() -> some View {
        self.modifier(textContentView())
    }
    
    public func textTimeStyle() -> some View {
        self.modifier(textRepeatedTimesView())
    }
    
    public func textRepeatedTimesStyle() -> some View {
        self.modifier(textTimeView())
    }
    
    public func textEndDateStyle() -> some View {
        self.modifier(textEndDateView())
    }
}


