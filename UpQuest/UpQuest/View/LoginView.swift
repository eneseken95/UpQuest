//
//  LoginView.swift
//  UpQuest
//
//  Created by Enes Eken on 14.07.2025.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var viewModel: UserViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Login")
                .font(.largeTitle.bold())

            TextField("Username", text: $viewModel.inputUsername)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)

            SecureField("Password", text: $viewModel.password)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)

            Button(action: {
                Task { await viewModel.login() }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                } else {
                    Text("Login")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .disabled(viewModel.isLoading)
        }
        .padding()
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}
