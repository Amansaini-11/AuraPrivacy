<div align="center">

<!-- Animated Header -->
<img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=6,11,20&height=200&section=header&text=Aura%20Privacy&fontSize=60&fontColor=fff&animation=fadeIn&fontAlignY=38&desc=Your%20Privacy.%20On%20Device.%20Always.&descAlignY=60&descSize=18" width="100%"/>

<!-- App Icon Placeholder -->
<br/>

<!-- Animated Typing -->
<a href="https://github.com/Amansaini-11/AuraPrivacy">
  <img src="https://readme-typing-svg.demolab.com?font=SF+Pro+Display&weight=600&size=22&pause=1000&color=6C63FF&center=true&vCenter=true&width=600&lines=AI-Powered+iOS+Privacy+Auditor;Runs+100%25+On-Device+%F0%9F%94%92;No+Data+Ever+Leaves+Your+Phone;Built+with+Apple+Intelligence+%F0%9F%A4%96" alt="Typing SVG" />
</a>

<br/><br/>

<!-- Badges Row 1 -->
![Swift](https://img.shields.io/badge/Swift-5.9-FA7343?style=for-the-badge&logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-4.0-0071E3?style=for-the-badge&logo=apple&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-17%2B-000000?style=for-the-badge&logo=apple&logoColor=white)
![Xcode](https://img.shields.io/badge/Xcode-15-1575F9?style=for-the-badge&logo=xcode&logoColor=white)

<!-- Badges Row 2 -->
![Apple Intelligence](https://img.shields.io/badge/Apple_Intelligence-On--Device_AI-8E44AD?style=for-the-badge&logo=apple&logoColor=white)
![Offline](https://img.shields.io/badge/Offline-100%25-27AE60?style=for-the-badge&logo=checkmarx&logoColor=white)
![Privacy](https://img.shields.io/badge/Zero_Data_Upload-Guaranteed-E74C3C?style=for-the-badge&logo=shield&logoColor=white)

<br/>

<!-- License & Stars -->
![GitHub stars](https://img.shields.io/github/stars/Amansaini-11/AuraPrivacy?style=social)
![GitHub forks](https://img.shields.io/github/forks/Amansaini-11/AuraPrivacy?style=social)

</div>

---

<div align="center">

## 🔐 What is Aura Privacy?

</div>

> **Aura Privacy** is an on-device iOS privacy auditor powered by **Apple Intelligence**. It reads your iPhone's local app privacy reports and tells you exactly which apps have been accessing your **microphone**, **camera**, **location**, and more — even in the background, even when you didn't know.
>
> **No internet required. No account needed. No data ever leaves your device. Ever.**

---

<div align="center">

## ✨ Features

</div>

<table align="center">
  <tr>
    <td align="center" width="200">
      <h3>🤖</h3>
      <b>Apple Intelligence</b><br/>
      <sub>On-device AI parses your iOS privacy reports automatically</sub>
    </td>
    <td align="center" width="200">
      <h3>📴</h3>
      <b>100% Offline</b><br/>
      <sub>Works without internet. Nothing is uploaded. Nothing is stored remotely.</sub>
    </td>
    <td align="center" width="200">
      <h3>⚡</h3>
      <b>2-Second Processing</b><br/>
      <sub>Custom NDJSON parser handles 5MB+ log files in under 2 seconds</sub>
    </td>
  </tr>
  <tr>
    <td align="center" width="200">
      <h3>🎯</h3>
      <b>Privacy Score</b><br/>
      <sub>Each app gets a consolidated score based on permission behaviour</sub>
    </td>
    <td align="center" width="200">
      <h3>📊</h3>
      <b>Visual Dashboard</b><br/>
      <sub>Complex logs simplified into a clean, shareable SwiftUI report</sub>
    </td>
    <td align="center" width="200">
      <h3>🔎</h3>
      <b>Deep Detection</b><br/>
      <sub>Catches background microphone, camera & location access you never approved</sub>
    </td>
  </tr>
</table>

---

<div align="center">

## 📸 Screenshots

</div>

<div align="center">

> 📌 *Add your app screenshots below — replace the placeholder paths with your actual image files*

<table>
  <tr>
    <td align="center">
      <img src="src/screenshots/dashboard.png" width="400" alt="Privacy Dashboard"/>
      <br/><sub><b>Privacy Dashboard</b></sub>
    </td>
    <td align="center">
      <img src="src/screenshots/appscan.png" width="400" alt="App Scan"/>
      <br/><sub><b>App Scan</b></sub>
    </td>
    <td align="center">
      <img src="src/screenshots/scanhistory.png" width="400" alt="Scan History"/>
      <br/><sub><b>Scan History</b></sub>
    </td>
    <td align="center">
      <img src="src/screenshots/settings.png" width="400" alt="Settings"/>
      <br/><sub><b>Settings</b></sub>
    </td>
  </tr>
</table>

</div>

---

<div align="center">

## 🎬 See It In Action

</div>

<div align="center">

> 📌 *Replace the link below with your actual demo video URL (YouTube, Loom, or direct mp4)*

[![Watch Demo](https://img.shields.io/badge/▶%20Watch%20Demo-Aura%20Privacy%20in%20Action-FF0000?style=for-the-badge&logo=youtube&logoColor=white)](https://youtube.com/your-demo-link-here)

<!-- If hosting video directly in repo, use this instead: -->
<!-- <video src="demo/aura-privacy-demo.mp4" width="600" controls></video> -->

</div>

---

<div align="center">

## 🏗 Tech Stack

</div>

```
Aura Privacy
├── 🧠  Apple Intelligence       — On-device AI for privacy report analysis
├── 🎨  SwiftUI                  — Entire UI layer, dashboard & reports
├── ⚙️  Swift Concurrency        — Async/Await for background NDJSON parsing
├── 🔗  Combine                  — Reactive data flow & state management
├── 📦  SwiftData                — Local data persistence
├── 🧩  MVVM Architecture        — Clean separation of concerns
├── 🛠  Dependency Injection     — Modular, testable service layer
└── 📂  NDJSON Parser (Custom)   — Processes 5MB+ logs in under 2 seconds
```

---

<div align="center">

## 🔄 How It Works

</div>

```mermaid
flowchart TD
    A[📱 Your iPhone] -->|Reads local privacy report| B[NDJSON Log Parser]
    B -->|Swift Concurrency background thread| C[Apple Intelligence]
    C -->|Analyzes permissions| D[Rule-Based Engine]
    D -->|Generates score| E[Privacy Score per App]
    E -->|SwiftUI renders| F[📊 Visual Dashboard]
    F -->|User exports| G[📤 Shareable Report]

    style A fill:#1a1a2e,color:#fff
    style B fill:#16213e,color:#fff
    style C fill:#0f3460,color:#fff
    style D fill:#533483,color:#fff
    style E fill:#6C63FF,color:#fff
    style F fill:#4ECDC4,color:#1a1a2e
    style G fill:#27AE60,color:#fff
```

---

<div align="center">

## 📁 Project Structure

</div>

```
AuraPrivacy/
├── 📂 App/
│   └── AuraPrivacyApp.swift
├── 📂 Models/
│   ├── PrivacyReport.swift
│   ├── AppPermission.swift
│   └── PrivacyScore.swift
├── 📂 ViewModels/
│   ├── DashboardViewModel.swift
│   └── ReportViewModel.swift
├── 📂 Views/
│   ├── DashboardView.swift
│   ├── PrivacyScoreView.swift
│   ├── AppDetailView.swift
│   └── ReportView.swift
├── 📂 Services/
│   ├── NDJSONParser.swift
│   ├── PrivacyAnalyzer.swift
│   └── ScoreEngine.swift
└── 📂 Resources/
    └── Assets.xcassets
```

---

<div align="center">

## 🚀 Getting Started

</div>

```bash
# 1. Clone the repository
git clone https://github.com/Amansaini-11/AuraPrivacy.git

# 2. Open in Xcode
cd AuraPrivacy
open AuraPrivacy.xcodeproj

# 3. Select your target device (iPhone with iOS 17+)
# 4. Build and run — no API keys, no setup, no internet needed
```

> ⚠️ **Requires iOS 17+** and an iPhone that supports **Apple Intelligence** for full functionality.

---

<div align="center">

## 👨‍💻 Built By

<img src="https://github.com/Amansaini-11.png" width="80" style="border-radius:50%"/>

**Aman Kumar Saini**
*iOS Developer · Jaipur, India*

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin.com/in/amansaini11)
[![GitHub](https://img.shields.io/badge/GitHub-Follow-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Amansaini-11)
[![Email](https://img.shields.io/badge/Email-Hire%20Me-D14836?style=for-the-badge&logo=gmail&logoColor=white)](mailto:sainiaman1090@gmail.com)

*Open to iOS Developer roles — Remote & India*

</div>

---

<div align="center">

## ⭐ Support

If you find this project interesting or useful, please consider giving it a star!
It helps more developers discover the project.

[![Star this repo](https://img.shields.io/github/stars/Amansaini-11/AuraPrivacy?style=for-the-badge&logo=github&label=Star%20this%20repo&color=6C63FF)](https://github.com/Amansaini-11/AuraPrivacy)

</div>

---

<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=6,11,20&height=100&section=footer" width="100%"/>

*Built with 🔒 privacy in mind · No data collected · No tracking · No compromise*

</div>
