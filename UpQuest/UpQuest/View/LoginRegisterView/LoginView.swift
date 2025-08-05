//
//  LoginView.swift
//  UpQuest
//
//  Created by Enes Eken on 14.07.2025.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var viewModel: UserViewModel
    @State private var username: String = ""
    @State private var password: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle")
                .resizable()
                .scaledToFill()
                .frame(width: 75, height: 75)
                .foregroundStyle(.white)

            Text("Login Page")
                .font(.title.bold())
                .foregroundStyle(.white)
                .padding(.bottom, 10)

            TextField("User name", text: $username)
                .fontWeight(.bold)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(white: 0.9), lineWidth: 1)
                )

            SecureField("Password", text: $password)
                .fontWeight(.bold)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(white: 0.9), lineWidth: 1)
                )

            Button(action: {
                Task { await viewModel.login(username: username, password: password) }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.3)
                        .padding()
                } else {
                    Text("Login")
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                }
            }
            .disabled(viewModel.isLoading)
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color("Background_Color"))
        .ignoresSafeArea()
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    hideKeyboard()
                }
        )
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(UserViewModel())
}
