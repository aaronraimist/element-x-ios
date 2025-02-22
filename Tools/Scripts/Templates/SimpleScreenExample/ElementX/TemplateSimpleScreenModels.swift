// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

// MARK: - Coordinator

enum TemplateSimpleScreenPromptType {
    case regular
    case upgrade
}

extension TemplateSimpleScreenPromptType: Identifiable, CaseIterable {
    var id: Self { self }
    
    var title: String {
        switch self {
        case .regular:
            return "Make this chat public?"
        case .upgrade:
            return "Privacy warning"
        }
    }
    
    var imageSystemName: String {
        switch self {
        case .regular:
            return "app.gift"
        case .upgrade:
            return "shield"
        }
    }
}

// MARK: View model

enum TemplateSimpleScreenViewModelAction {
    case accept
    case cancel
}

// MARK: View

struct TemplateSimpleScreenViewState: BindableState {
    var promptType: TemplateSimpleScreenPromptType
    var count: Int
}

enum TemplateSimpleScreenViewAction {
    case incrementCount
    case decrementCount
    case accept
    case cancel
}
