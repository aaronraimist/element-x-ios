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

import SwiftUI
import Combine

struct HomeScreenCoordinatorParameters {
    let userSession: UserSessionProtocol
    let attributedStringBuilder: AttributedStringBuilderProtocol
    let memberDetailProviderManager: MemberDetailProviderManager
}

enum HomeScreenCoordinatorAction {
    case logout
    case presentRoom(roomIdentifier: String)
    case presentSettings
}

final class HomeScreenCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: HomeScreenCoordinatorParameters
    private let hostingController: UIViewController
    private var viewModel: HomeScreenViewModelProtocol
    
    private var roomSummaries: [RoomSummary] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: ((HomeScreenCoordinatorAction) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: HomeScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = HomeScreenViewModel(attributedStringBuilder: parameters.attributedStringBuilder)
        
        let view = HomeScreen(context: viewModel.context)
        hostingController = UIHostingController(rootView: view)
        
        viewModel.callback = { [weak self] action in
            guard let self = self else { return }
            
            switch action {
            case .logout:
                self.callback?(.logout)
            case .selectRoom(let roomIdentifier):
                self.callback?(.presentRoom(roomIdentifier: roomIdentifier))
            case .tapUserAvatar:
                self.callback?(.presentSettings)
            }
        }
        
        parameters.userSession.clientProxy
            .callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                switch action {
                case .updatedRoomsList:
                    self?.updateRoomsList()
                }
            }.store(in: &cancellables)
        
        updateRoomsList()
        
        Task {
            if case let .success(userAvatarURLString) = await parameters.userSession.clientProxy.loadUserAvatarURLString() {
                if case let .success(avatar) = await parameters.userSession.mediaProvider.loadImageFromURLString(userAvatarURLString) {
                    self.viewModel.updateWithUserAvatar(avatar)
                }
            }
            
            if case let .success(userDisplayName) = await parameters.userSession.clientProxy.loadUserDisplayName() {
                self.viewModel.updateWithUserDisplayName(userDisplayName)
            }
        }
    }
    
    // MARK: - Public
    func start() {
        
    }
    
    func toPresentable() -> UIViewController {
        return self.hostingController
    }
    
    // MARK: - Private
    
    func updateRoomsList() {
        roomSummaries = parameters.userSession.clientProxy.rooms.compactMap { roomProxy in
            guard !roomProxy.isSpace, !roomProxy.isTombstoned else {
                return nil
            }
            
            if let summary = self.roomSummaries.first(where: { $0.id == roomProxy.id }) {
                return summary
            }
            
            let memberDetailProvider = parameters.memberDetailProviderManager.memberDetailProviderForRoomProxy(roomProxy)
            
            return RoomSummary(roomProxy: roomProxy,
                               mediaProvider: parameters.userSession.mediaProvider,
                               eventBriefFactory: EventBriefFactory(memberDetailProvider: memberDetailProvider))
        }
        
        viewModel.updateWithRoomSummaries(roomSummaries)
    }
}
