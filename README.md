# 🛒 Bajrang Distributors App

![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0%2B-0175C2?logo=dart)
![Hive](https://img.shields.io/badge/Database-Hive%20NoSQL-orange)
![State](https://img.shields.io/badge/State-Riverpod-purple)
![License](https://img.shields.io/badge/License-MIT-green)

A comprehensive **Offline Sales & Order Management System** built with Flutter. Designed for distributors to manage products, customers, and orders efficiently without requiring an active internet connection.

---

## 📱 App Overview

**Bajrang Distributors App** replaces traditional pen-and-paper order booking. It allows sales representatives to browse digital catalogs, manage complex unit conversions (e.g., Bag vs. Kg), generate PDF invoices instantly, and track order history.

### 🌟 Key Features

* **📦 Master Data Management:**
    * Add/Edit Products & Customers manually.
    * **Bulk Import** from Excel (XLSX) for fast setup.
    * Smart Grouping & Categorization of items.
* **🛒 Advanced Order Booking:**
    * **Real-time Search** with auto-expanding categories.
    * **Multi-Unit Support:** Seamlessly switch between Primary (e.g., Bag) and Secondary (e.g., Kg) units with auto-price calculation.
    * Manual Price Overrides & Discount management.
* **📄 PDF Invoicing:**
    * Generate professional invoices with automatic Serial No. & Alphabetical sorting.
    * "With Price" and "Without Price" PDF options for sharing catalogs.
* **⚡ Dashboard & Analytics:**
    * Quick stats: Today's Orders, Pending Actions.
    * Track Approved vs. Pending orders.
    * **Re-Order Logic:** Easily re-add rejected/shortage items to new orders.
* **💾 100% Offline:** Uses **Hive Database** for lightning-fast local storage.

---

## 📸 Screenshots

| Dashboard | Place Order | Order History | PDF Invoice |
|:---:|:---:|:---:|:---:|
| <img width="540" height="1152" alt="image" src="https://github.com/user-attachments/assets/b1e29186-4e7e-4980-af5f-560dea76982e" />
 | <img width="540" height="1146" alt="image" src="https://github.com/user-attachments/assets/d1823cec-69d0-4b96-988c-6ce7821f80e9" />
 | <img width="540" height="1156" alt="image" src="https://github.com/user-attachments/assets/dfcd1e40-aeaf-4cbc-a725-6a385580de3b" />
  | <img width="901" height="1280" alt="image" src="https://github.com/user-attachments/assets/24ecbca2-8237-4588-9979-cdaa667da512" />
|

---

## 🛠️ Tech Stack

* **Framework:** Flutter (Dart)
* **State Management:** Flutter Riverpod
* **Local Database:** Hive (NoSQL)
* **File Handling:** Excel (import), PDF (export), Path Provider
* **UI Components:** Material Design 3

---

## 📥 Excel Import Formats

To bulk import data, your Excel files must follow these column structures:

### 1. Products Import
| Col A | Col B | Col C | Col D | Col E | Col F | Col G | Col H |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Group** | **Category** | **Name** | **Unit 1** | **Price** | **Image** | **Unit 2** | **Desc** |
| Spices | Powder | Haldi | Pkt | 450 | *(path)* | Box | 20 Pkt |

* *Note: Column H (Description) is used to extract the Conversion Factor (e.g., "20 Pkt" -> 20).*

### 2. Customers Import
| Col A | Col B | Col C |
| :--- | :--- | :--- |
| **Name** | **Phone** | **Address** |
| Ravi Kirana | 9876543210 | Main Market, Hyd |

---

## 🚀 Installation

1.  **Clone the Repo**
    ```bash
    git clone [https://github.com/Ashi-run/bajrang_distributor_app.git](https://github.com/Ashi-run/bajrang_distributor_app.git)
    cd bajrang_distributor_app
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Run the App**
    ```bash
    flutter run
    ```

4.  *(Optional)* **Build APK**
    ```bash
    flutter build apk --release
    ```

---

## 👤 Developer

**Developed by Ashi** *Computer Science & Data Science Student* *NMIMS Hyderabad*

&copy; 2025 All Rights Reserved.
