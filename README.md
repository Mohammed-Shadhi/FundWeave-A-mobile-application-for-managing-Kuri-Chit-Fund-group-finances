FundWeave

A mobile application for managing Kuri (Chit Fund) group finances

FundWeave is a full-stack mobile application designed to simplify the management of Kuri (Chit Fund) groups. It provides structured workflows for managing members, payments, approvals, and receipts while focusing on reliability and ease of use.

«Status: 🚧 Currently in development / Pre-release»

About the Project

FundWeave was independently designed and developed as an end-to-end product, covering the application architecture, data model, user interface, business logic, and backend integration.

The project focuses on translating real-world Kuri management workflows into a structured digital system rather than simply digitizing records.

Key Features

💳 Payment Management

- Tracks payments through Pending, Approved, and Rejected states
- Provides an admin approval workflow for payment verification
- Maintains a structured payment lifecycle

🧾 Reliable Receipt Generation

- Uses Firestore batch writes to keep payment approval and receipt generation consistent
- Designed to reduce inconsistent transaction records

👤 Authentication

- Built on Firebase Authentication
- Supports username-oriented identification
- Retains phone OTP authentication
- Designed around how the target users naturally identify and access their accounts

🔥 Firebase Backend

- Firebase Authentication for user authentication
- Cloud Firestore for application data
- Structured data models for managing Kuri-related information

Tech Stack

Area| Technology
Mobile| Flutter / Dart
State Management| Riverpod
Backend| Firebase
Database| Cloud Firestore
Authentication| Firebase Authentication
Version Control| Git & GitHub

My Role

This is an independent project.

I designed and built FundWeave end-to-end, including:

- Product and feature planning
- Application architecture
- Firestore data modelling
- Flutter UI development
- State management
- Authentication
- Payment and approval workflows
- Backend integration
- Receipt-generation logic

Product Decisions

A major focus of FundWeave is trust and reliability.

For example, payment approval and receipt generation are handled using Firestore batch operations so related database updates can be performed together rather than leaving partially updated transaction records.

The authentication flow was also designed around the intended users rather than defaulting to an email-first experience.

Project Structure

FundWeave/
├── lib/
│   ├── models/
│   ├── screens/
│   ├── services/
│   ├── providers/
│   └── widgets/
├── android/
├── ios/
├── web/
└── pubspec.yaml

The exact structure may evolve as development continues.

Current Status

FundWeave is currently under active development and has not yet been publicly released.

Additional development, testing, and refinement are ongoing before release.

Future Development

Planned areas of development include:

- Further UI/UX refinement
- Expanded financial reporting
- Improved administrative workflows
- Testing and reliability improvements
- Production deployment

Author

Mohammed Shadhi
B.Tech Computer Science & Engineering — Expected 2027

LinkedIn: https://www.linkedin.com/in/mohammed-shadhi-6b0625291

Github  : https://github.com/Mohammed-Shadhi

---

FundWeave is a personal project built to explore the intersection of product development, financial workflow management, and full-stack mobile application development.