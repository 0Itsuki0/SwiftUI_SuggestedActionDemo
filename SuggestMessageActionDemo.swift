//
//  SuggestMessageAction.swift
//  iOSDemo7
//
//  Created by Itsuki on 2026/08/05.
//

import SuggestedActions
import SwiftUI

struct User: Identifiable, Hashable {
    var name: String
    // Common handles: the email address or phone number
    // but for SuggestedActionsMessage.Participant purpose,
    // it can be any string that uniquely identifies a participant within the app’s user identity system.
    var handle: String

    var id: String {
        handle
    }
}

struct Message: Identifiable, Hashable {
    var id: UUID = UUID()
    var text: String
    var user: User

    // true if the participant is the user of this device
    // false for other participants.
    var isUser: Bool
}

struct SuggestMessageActionDemo: View {
    @State private var messages: [Message] = []
    @State private var currentParticipant: User = .init(
        name: "itsuki-current",
        handle: "itsuki@current.com"
    )
    @State private var otherParticipants: [User] = [
        .init(name: "itsuki-other", handle: "itsuki@other.com")
    ]

    @State private var text: String = "a meeting a 7am tomorrow."
    @State private var loadedSuggestedActions: Set<Message.ID> = []

    var body: some View {
        NavigationStack {

            ScrollViewReader { proxy in
                List {
                    if messages.isEmpty {
                        ContentUnavailableView(
                            "No Messages",
                            systemImage: "ellipsis.message.fill"
                        )
                    }
                    ForEach(messages.enumerated(), id: \.element.id) {
                        index,
                        message in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(message.text)
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8).fill(
                                        .white
                                    )
                                )

                            // show the SuggestedActionsView only when loading finish
                            // to avoid displaying a loading state when the view appears.
                            if self.loadedSuggestedActions.contains(message.id)
                            {
                                SuggestedActionsView(
                                    message: self.makeSuggestedActionsMessage(
                                        for: message
                                    ),
                                    previousMessages: self.messages.prefix(
                                        index
                                    ).suffix(
                                        SuggestedActionsMessage
                                            .previousMessagesLimit
                                    ).map({
                                        self.makeSuggestedActionsMessage(
                                            for: $0
                                        )
                                    })
                                )
                                .font(.custom("Avenir-Medium", size: 16))
                                .fixedSize(horizontal: true, vertical: false)
                                .tint(.blue.opacity(0.2))
                            }

                        }
                        .listRowBackground(Color.clear)
                        .frame(
                            maxWidth: .infinity,
                            alignment: message.isUser ? .trailing : .leading
                        )
                        .padding(message.isUser ? .leading : .trailing, 8)
                    }
                }
                .onChange(of: messages.count) {
                    proxy.scrollTo(messages.count - 1, anchor: .bottom)
                }
            }
            .navigationTitle("Suggested Actions")
            .toolbarTitleDisplayMode(.inlineLarge)
            .listRowSpacing(8)
            .contentMargins(.top, 8)
            .listRowSeparator(.hidden)
            .safeAreaInset(edge: .bottom) {
                HStack(alignment: .top, spacing: 16) {
                    TextField(
                        "Some message...",
                        text: $text,
                        axis: .vertical
                    )
                    .lineLimit(5, reservesSpace: false)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        guard
                            text.trimmingCharacters(in: .whitespacesAndNewlines)
                                .isEmpty
                        else {
                            return
                        }
                        self.sendMessage()
                    }
                    Button(
                        action: {
                            self.sendMessage()
                        },
                        label: {
                            Image(systemName: "paperplane.fill")
                                .frame(width: 32, height: 32)
                        }
                    )
                    .disabled(
                        text.trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty
                    )
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background(.white)
            }
            .buttonStyle(.plain)

        }
    }

    private func sendMessage() {
        let message = Message(
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            user: currentParticipant,
            isUser: true
        )
        // ---
        // send the message to the server as needed
        // ---
        Task {
            await SuggestedActionsView.generate(
                message: makeSuggestedActionsMessage(for: message),
                previousMessages: self.messages.suffix(
                    SuggestedActionsMessage
                        .previousMessagesLimit
                ).map({
                    self.makeSuggestedActionsMessage(for: $0)
                })
            )
            self.loadedSuggestedActions.insert(message.id)
        }

        self.messages.append(message)
        text = ""
    }

    private func makeSuggestedActionsMessage(
        for message: Message
    ) -> SuggestedActionsMessage {
        let suggestedActionMessage: SuggestedActionsMessage = .init(
            id: message.id,
            date: Date(),
            subject: nil,
            body: .init(stringLiteral: message.text),
            sender: .init(
                name: currentParticipant.name,
                handle: currentParticipant.handle,
                isUser: message.isUser
            ),
            recipients: otherParticipants.map({
                .init(name: $0.name, handle: $0.handle, isUser: false)
            })
        )
        return suggestedActionMessage
    }
}
