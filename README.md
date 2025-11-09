# Seismo

## Overview
Seismo is a real-time earthquake detection and alert system designed to enhance personal safety during natural disasters. Leveraging an iPhone’s built-in sensors, Seismo detects seismic activity and automatically notifies trusted contacts through SMS alerts. In addition to disaster alerts, the app provides users with a Health ID and Profile feature to store vital medical information.

## Features
- **Real-time Earthquake Detection**  
  Uses the iPhone’s gyroscope, accelerometer, and barometer to detect seismic motion and environmental changes in real time.

- **Automated SMS Alerts**  
  Instantly sends alert messages to preselected emergency contacts when an earthquake is detected.

- **Health ID**  
  Allows users to securely store and share key medical details such as name, blood type, weight, height, allergies, and emergency contacts.

- **User Profile**  
  Users can manage personal details and update emergency information for accurate alert and response handling.

## Tech Stack
- **Language:** Swift  
- **Framework:** UIKit / SwiftUI (as applicable)  
- **Platform:** iOS  
- **APIs:**  
  - CoreMotion for sensor access (accelerometer, gyroscope)  
  - CoreLocation for determining user coordinates  
  - Twilio for SMS integration

## Installation & Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/<your-username>/Seismo.git
   ```
2. Open the project in **Xcode**:
   ```bash
   cd Seismo
   open Seismo.xcodeproj
   ```
3. Configure the necessary API keys in the project settings (if applicable).  
4. In **Xcode**, select a simulator or a physical device and press **Run (⌘ + R)**.  
5. Ensure permissions for location, motion sensors, and SMS access are granted on the device.

## How to Run
1. Launch the app on your iOS device.  
2. Create a new **Profile** by entering your name, age, and basic details.  
3. Add your **Health ID** information and emergency contacts.  
4. Enable **Earthquake Detection Mode** from the main dashboard.  
5. If a seismic event is detected, the app automatically sends an SMS alert to your saved contacts and displays a safety notification.
   
_Note that due to limited Twilio subscription, to successfully text a number we must manually verify it first. If you intend to use this feature during testing, please send an email to (almoayal@mcmaster.ca) to verify your number, or send an alert to a previously verified number._

## Future Improvements
- Multi-language support.  
- Expansion to detect other disasters such as floods or tsunamis.

## Authors & Credits
**Developed by:**  
- Luna Almoayad
- Sama Al-Oda
- Tasnim Ayderus  
- Thaneesha Sivasithambaram

**Acknowledgments:**  
- Apple Developer Documentation for CoreMotion and MessageUI frameworks.
