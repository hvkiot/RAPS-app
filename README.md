# RAPS Diagnostic App

Welcome to the **RAPS Diagnostic App**! This application serves as a smart, user-friendly mobile interface for monitoring, diagnosing, and interacting with heavy-duty hardware systems (like electronic control units) in real-time. 

Instead of dealing with complex wired tools and technical interfaces, this app brings all the necessary diagnostic insights right to your smartphone or tablet with a few simple taps.

---

## 📱 User Experience & End-to-End Flow

### 1. Launch & Setup
When you first open the app, it prepares itself to communicate with your hardware. To do this, it will politely ask for **Bluetooth and Location permissions**, which are standard requirements for finding nearby smart devices. 

### 2. Searching for Hardware (Scan Screen)
Once permissions are granted, the application acts as a radar. The **Scan Screen** searches the immediate area for the RAPS Bluetooth Bridge (the device plugged into the hardware).
*   Any discovered RAPS components will appear on a list.
*   The user simply taps their designated device on the screen to connect.

### 3. Establishing the Connection
After tapping the device, the app securely pairs with the Bluetooth Bridge. At this stage, the app does a quick check to see if the main brain of the vehicle/hardware (the ECU) is officially "Online" and ready to share data. 

### 4. The Main Dashboard 
Once connected securely, the app brings you to the Main Dashboard—the control center.
*   **Live Sensor Data:** Instead of raw code, you see beautiful, easy-to-read gauges and numbers representing things like steering angles, fluid pressures, and overall system health.
*   **Visual Graphs:** Real-time data points are mapped onto interactive graphs, allowing you to visually see trends, spikes, or drops over time.
*   **Active Diagnostics:** With simplified buttons, you can trigger specific system checks or calibrations, allowing the app to do the heavy technical lifting in the background.

### 5. Smart Disconnection Handling
We know that in real-world environments, connections can be interrupted. The app is built to handle this gracefully:
*   **Live Status Updates:** If the hardware temporarily loses power or stops communicating, the app immediately shows an "Offline" badge but keeps striving to re-establish the link quietly in the background.
*   **Automatic Rerouting:** If the Bluetooth connection drops completely or you walk out of range, the app automatically transitions you back out to the **Scan Screen**. From there, you can easily reconnect as soon as you are back within range.

---
*Built to make complex diagnostics accessible to everyone.*
