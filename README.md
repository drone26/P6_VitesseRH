# VitesseRH 🚀

**VitesseRH** is a professional iOS application designed for HR recruiters to streamline candidate pipeline management. Built with **SwiftUI** and a robust **MVVM** architecture, it provides a secure, reactive, and highly testable environment for recruitment operations.

## ✨ Features

* **Secure Authentication**: Integrated login and registration system using **Keychain** for persistent and secure token storage.
* **Candidate Management**: Complete CRUD operations (Create, Read, Update, Delete) for tracking recruitment prospects.
* **Pipeline Optimization**: Mark high-priority candidates as favorites for quick access in the dashboard.
* **Advanced Search**: Real-time filtering of candidates by name or email through a dedicated search interface.
* **Role-Based Access**: Specialized views and permissions for Admin users to ensure data integrity.
* **Responsive UI**: Modern layouts optimized for various iOS devices using declarative SwiftUI components.

## 🛠 Tech Stack

* **Language**: Swift 5.10+
* **Framework**: SwiftUI
* **Architecture**: MVVM (Model-View-ViewModel)
* **Networking**: Protocol-oriented `APIService` utilizing `URLSession` and `async/await`
* **Security**: Actor-based `KeychainService` for thread-safe handling of sensitive data
* **Testing**: Comprehensive test suites for ViewModels and Backend services using `XCTest`

## 🏗 Project Architecture

The project is structured to enforce a clean separation of concerns:

* **Models**: Decodable data structures representing candidates, authentication responses, and API endpoints.
* **Services**: `Actor`-based services (e.g., `CandidateBackendService`) that handle data isolation and external API communication.
* **ViewModels**: Manage UI state and business logic, utilizing `@Published` properties for seamless SwiftUI updates.
* **Views**: Declarative SwiftUI components focused on layout and user interaction.

## 🧪 Testing and Quality Assurance

Quality is a core pillar of the VitesseRH project. The application includes an extensive testing layer:

* **Unit Tests**: Isolated testing of business logic within ViewModels, such as login validation and registration flows.
* **Integration Tests**: Testing the `CandidateBackendService` with a `MockURLSession` to verify API request construction and response parsing.
* **Security Testing**: Verifying Keychain interactions through a `MockKeychain` to ensure tokens are securely saved and retrieved.

## 🚀 Getting Started

1.  **Clone the repository**: `git clone <repository-url>`
2.  **Open Project**: Launch `VitesseRH.xcodeproj` in Xcode.
3.  **Configure API**: Ensure the `CandidateAPIURL` in `GlobalConstant.swift` points to your active backend environment.
4.  **Run**: Select a target device and press `Cmd + R`.
5.  **Test**: Execute the test suite using `Cmd + U` to ensure environment stability.

---

### 👤 Author
**Mathieu ARRIO**
* *Project Initialized: February 2026*
