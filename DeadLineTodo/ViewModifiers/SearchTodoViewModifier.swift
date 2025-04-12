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

struct textTitleView: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(Color.blackGray)
            .bold()
            .padding(.horizontal, -2)
            .font(.system(size: 10))
    }
}

struct imageIconView: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(5)
            .bold()
            .font(.system(size: 20))
            .foregroundStyle(Color.blackBlue2)
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
    
    public func textTitleStyle() -> some View {
        self.modifier(textTitleView())
    }
    
    public func imageIconStyle() -> some View {
        self.modifier(imageIconView())
    }
}


