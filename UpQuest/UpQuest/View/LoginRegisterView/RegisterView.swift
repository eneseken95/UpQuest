//
//  RegisterView.swift
//  UpQuest
//
//  Created by Enes Eken on 14.07.2025.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var viewModel: UserViewModel
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.plus")
                .resizable()
                .scaledToFill()
                .frame(width: 75, height: 75)
                .foregroundStyle(.white)

            Text("Register")
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

            TextField("Email", text: $email)
                .fontWeight(.bold)
                .keyboardType(.emailAddress)
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
                Task { await viewModel.register(username: username, email: email, password: password) }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                } else {
                    Text("Sign Up")
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
    RegisterView()
        .environmentObject(UserViewModel())
}
