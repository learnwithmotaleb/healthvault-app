# Health Vault – Mobile API Integration Guide

This guide covers the patient app and the provider app. The admin dashboard has its own endpoints, which aren't listed here.

Every example below is a real response recorded from the API. Arrays are shortened to one item and tokens are cut short with `…`.

---

## Contents

1. [Basics](#1-basics)
2. [Authentication & tokens](#2-authentication--tokens)
3. [Files & images](#3-files--images)
4. [Errors](#4-errors)
5. [Realtime (Socket.io) & push (OneSignal)](#5-realtime-socketio--push-onesignal)
6. [Auth endpoints](#6-auth-endpoints)
7. [Profile & settings](#7-profile--settings)
8. [Patient home & health card](#8-patient-home--health-card)
9. [Provider directory & favorites](#9-provider-directory--favorites)
10. [Appointments](#10-appointments)
11. [Medication reminders & adherence](#11-medication-reminders--adherence)
12. [Health logs](#12-health-logs)
13. [Insurance](#13-insurance)
14. [Medical documents vault](#14-medical-documents-vault)
15. [SOS / emergency](#15-sos--emergency)
16. [Support chat](#16-support-chat)
17. [Notifications](#17-notifications)
18. [Provider app: services & availability](#18-provider-app-services--availability)
19. [Content (articles, FAQ, legal)](#19-content-articles-faq-legal)
20. [Enums & limits](#20-enums--limits)
21. [GDPR (export / delete account)](#21-gdpr-export--delete-account)

---

## 1. Basics

| Item | Value |
|---|---|
| Base URL | `{SERVER_URL}/api/v1` (e.g. `https://api.yourdomain.com/api/v1`) |
| Format | JSON (`Content-Type: application/json`), except uploads (`multipart/form-data`) |
| Dates | ISO-8601 strings in **UTC** (e.g. `2026-11-30T08:00:00.000Z`). Convert to local time for display |
| App timezone | **Europe/Athens**. Reminder times (`"08:00"`), provider slots and "today" are in Greek time |
| IDs | MongoDB ObjectId strings (24 hex chars) |

### Success response (always this shape)

```json
{
  "success": true,
  "message": "Login successful",
  "statusCode": 200,
  "data": { }
}
```

### Paginated lists

Add query params `?page=1&limit=10` (`limit` max 100) and, where supported, `searchTerm=`. Paginated responses look like this:

```json
{
  "success": true,
  "statusCode": 200,
  "message": "...",
  "data": {
    "meta": { "page": 1, "limit": 10, "total": 25, "totalPage": 3 },
    "data": [ ]
  }
}
```

> Some short lists (reminders, insurances, favorites, availability, my services) return a plain array in `data`, with no `meta`. Each endpoint below says which shape it returns.

### Two IDs per user

| Name | Meaning |
|---|---|
| `user._id` / `jwtPayload.id` | The **account** id (User) |
| `profileId` / `user.profile._id` | The **role profile** id (patient profile or provider profile). Appointments, favorites, `providerId`, etc. use this one |

---

## 2. Authentication & tokens

**Header for every protected endpoint:**

```
Authorization: Bearer <accessToken>
```

| Token | Lifetime | Use |
|---|---|---|
| `accessToken` | 1 day | Send in the `Authorization` header |
| `refreshToken` | 30 days | Get a new access token: `POST /auth/refresh-token` |

**Recommended flow:**

1. Store both tokens in secure storage (Keychain / Keystore).
2. On any `401` response, call `POST /auth/refresh-token` with `{ "refreshToken": "..." }`, then retry the request once.
3. If the refresh also returns `401`, clear the tokens and go to the login screen.
4. A `403` with message `User is Blocked` means the account was blocked by an admin. Log the user out.
5. After **change password** or **reset password**, the server returns new tokens and the old ones stop working. Save the new ones.

**Roles:** `NORMALUSER` (patient), `PROVIDER` (doctor, clinic, pharmacy…). The table header of each endpoint shows which role it needs.

**Rate limits:**
- Login, register and OTP endpoints allow 30 requests per 15 minutes per IP.
- All other endpoints allow 300 requests per minute.
- Going over a limit returns `429`.

---

## 3. Files & images

All files are stored on **AWS S3**.

| Field returned | Example value | How to display |
|---|---|---|
| Public files: `profile_image`, article `article_image` | `https://dxxxx.cloudfront.net/uploads/public/images/profile/1795583822601-me.png` | Use the URL directly |
| Private files: `file` (documents), `insurance_Photo`, `prescription_file`, `identification_images` | `uploads/private/6b06…/documents/1795583823038-532b….pdf` | `GET {SERVER_URL}/{value}` **with the `Authorization` header** |
| Legacy (uploaded before the migration) | `uploads/images/profile/xxx.png` | `{SERVER_URL}/{value}` |

**Rule:** if the value starts with `http`, use it as-is. Otherwise build `{SERVER_URL}/{value}`, and if it contains `uploads/private/`, add the auth header.

```dart
// Flutter example
Image.network('$serverUrl/${doc.file}', headers: {'Authorization': 'Bearer $token'});
```

Private files can only be opened by their owner. Any other user gets `403`, and a request without a token gets `401`.

### Uploading (multipart/form-data)

Endpoints that accept files use **one text field `data` containing a JSON string**, plus the file fields:

```
POST /api/v1/insurance/create
Content-Type: multipart/form-data

data            = {"forWhom":"SELF","name":"Family plan","number":"POL-1","insuranceProvider":"Interamerican","expiryDate":"2026-12-15"}
insurance_Photo = <binary file>
```

| File field | Allowed types | Max files | Used in |
|---|---|---|---|
| `profile_image` | jpg, jpeg, png, webp | 1 | register, update profile |
| `identification_images` | jpg, png, webp, pdf | 1 | provider register (required) |
| `insurance_Photo` | jpg, png, webp, pdf | 1 | insurance create/update |
| `document` | jpg, png, webp, pdf | 5 | medical documents upload |
| `prescription_file` | jpg, png, webp, pdf | 1 | reminder create/update |

- The max size is **10 MB per file**; a bigger file returns `400 "File is too large (max 10MB)"`.
- A file in an unknown field returns `400 "Unexpected file field"`.
- A wrong file type returns `400 "Invalid file type for …"`.

> The endpoints that accept multipart also accept plain JSON when you don't send a file.

---

## 4. Errors

```json
{
  "success": false,
  "message": "email: Invalid email format",
  "statusCode": 400,
  "error": [ { "path": "email", "message": "Invalid email format" } ],
  "stack": null
}
```

Show `message` to the user. `error[].path` tells you which form field is wrong, so you can highlight it.

| Status | Meaning |
|---|---|
| 400 | Validation error / bad request (read `message`) |
| 401 | Missing, invalid or expired token → refresh token |
| 403 | Blocked, email not verified, or wrong role |
| 404 | Not found (or not yours) |
| 409 | Conflict (email already used, time slot already booked, duplicate…) |
| 429 | Too many requests / too many wrong OTP attempts |
| 500 | Server error |

---

## 5. Realtime (Socket.io) & push (OneSignal)

### Socket.io (in-app live updates)

```js
import { io } from 'socket.io-client';
const socket = io(SERVER_URL, { auth: { token: accessToken }, transports: ['websocket'] });
```

- An invalid token is rejected with `connect_error: "Unauthorized"`.
- Reconnect with the new token after you refresh it.

| Event (server → app) | Payload | When |
|---|---|---|
| `notification` | Notification object (same as in [§17](#17-notifications)) | Any new notification for this user |
| `notification-count` | `{ "unreadCount": 0 }` | After "mark all as read" |
| `support-message` | `{ "conversation": {...}, "message": {...} }` | Support team replied |
| `support-status` | `{ "status": "OPEN" \| "CLOSED" }` | Chat closed / reopened by support |

### Push notifications (OneSignal)

1. Initialise the OneSignal SDK in the app and get the device **player / subscription id**.
2. Send it as `playerId` in **register** and/or **login**. The server links the device to that account; a device belongs to one account at a time.
3. On logout, call `POST /auth/logout` with `{ "playerId": "..." }` so the device stops receiving pushes.

A push carries a title, a message and a `data` object, which is the same `data` as the in-app notification. Use it to open the right screen:

| `data` key | Open screen |
|---|---|
| `appointmentId` | Appointment details |
| `reminderId` + `scheduledAt` | "Did you take your medicine?" (call [record intake](#record-a-dose-taken--skipped)) |
| `insuranceId` | Insurance details |
| `documentId` | Document details |
| `conversationId` | Support chat |
| `providerId` + `approvalStatus` | Provider: approval result |
| `campaignId` | General announcement |

System texts come in the user's language (`en` or `el`), taken from `settings.language`.

---

## 6. Auth endpoints

### Register – patient
`POST /user/register` · public · JSON **or** multipart (`data` + optional `profile_image`)

| Field | Type | Required | Rules |
|---|---|---|---|
| role | string | ✅ | `"NORMALUSER"` |
| fullName | string | ✅ | 1–100 chars |
| email | string | ✅ | valid email (stored lowercase) |
| password | string | ✅ | 8–128 chars |
| phone | string | ✅ | 6–20 chars, **unique** |
| dateOfBirth | date | ✅ | `"1990-05-01"`, not in future |
| gender | string | ✅ | `MALE` \| `FEMALE` \| `OTHER` |
| bloodGroup | string | ✅ | `A+ A- B+ B- AB+ AB- O+ O-` |
| acceptPrivacyPolicy | boolean | ✅ | must be `true` (GDPR consent) |
| address | string | | ≤ 300 |
| emergencyContacts | array | | max 5 × `{ name, phone, relation? }` |
| emergencyContact | string | | single phone (legacy, optional) |
| identificationNumber | string | | ≤ 50 |
| allergies | string[] | | max 30 |
| chronicConditions | string[] | | max 30 |
| membershipId | string | | auto-generated (`HV-XXXXXXXX`) if missing |
| language | string | | `en` (default) \| `el` |
| playerId | string | | OneSignal device id |

```json
{
  "role": "NORMALUSER",
  "fullName": "Maria Papadopoulou",
  "email": "maria@example.com",
  "password": "Patient123",
  "phone": "6900000001",
  "dateOfBirth": "1990-05-01",
  "gender": "FEMALE",
  "bloodGroup": "A+",
  "address": "Athens",
  "emergencyContacts": [{ "name": "Nikos Papadopoulos", "phone": "6900000009", "relation": "Brother" }],
  "allergies": ["penicillin"],
  "chronicConditions": ["asthma"],
  "language": "el",
  "playerId": "onesignal-player-id",
  "acceptPrivacyPolicy": true
}
```

**201**

```json
{
  "success": true,
  "message": "Registered successfully. A verification code was sent to your email.",
  "statusCode": 201,
  "data": { "_id": "6b066f4e46381fd9a0df2367", "email": "maria@example.com", "role": "NORMALUSER", "isVerifyEmailOTPVerified": false, "emailSent": true }
}
```

- Next, show the OTP screen and call [verify email](#verify-email-otp-auto-login).
- If `emailSent` is `false`, show a "Resend code" button.
- Registering again with an email that was never verified replaces the old unverified account.

### Register – provider
`POST /user/register` · public · **multipart**: `data` (JSON) + `identification_images` (**required**) + `profile_image` (optional)

`data` fields: `role: "PROVIDER"`, `fullName`, `email`, `password`, `phone`, `acceptPrivacyPolicy: true`, `providerTypeId` (from `GET /provider-types`), plus:

| Field | Type | Notes |
|---|---|---|
| serviceId | string[] | Catalogue service ids for the provider type (`GET /service/admin-service/{TYPE_KEY}`) |
| specialization | string | **required for DOCTOR** |
| medicalLicenseNumber | string | **required for DOCTOR** |
| yearsOfExperience | number | 0–80 |
| languages | string[] | e.g. `["Greek","English"]` |
| displayName | string | business / clinic name |
| about | string | ≤ 2000 |
| address | string | |
| location | string | city / area (used for directory filter) |
| identificationNumber, drugLicenseNumber, businessRegistrationNumber | string | |
| licenseExpiryDate | date | |
| language, playerId | | same as patient |

Response: same as the patient one. After email verification, the provider is `approvalStatus: "PENDING"`:
- They can log in, but they don't appear in the directory and can't be booked.
- When an admin approves or rejects them, they get a push notification with `data.approvalStatus`.

### Verify email OTP (auto login)
`POST /auth/verify-email-otp` · public

```json
{ "email": "maria@example.com", "otp": "123456" }
```

**200** returns the tokens and the full user (same shape as login), so you can skip the login screen:

```json
{
  "success": true,
  "message": "Email verified successfully",
  "statusCode": 200,
  "data": {
    "message": "Email verified successfully",
    "accessToken": "eyJhbGciOi…",
    "refreshToken": "eyJhbGciOi…",
    "user": { "_id": "…", "fullName": "Maria Papadopoulou", "role": "NORMALUSER", "profile": { } }
  }
}
```

Errors:
- `400 Incorrect code`
- `400 Code expired. Request a new one.` (codes are valid 10 minutes)
- `429 Too many wrong attempts. Request a new code.` (after 5 wrong tries)

### Resend OTP
`POST /auth/resend-otp` · public

```json
{ "email": "maria@example.com", "purpose": "verify" }
```

`purpose`: `verify` (sign-up email) or `reset` (forgot password). The API always replies with **200** `{ "message": "If this email is registered, a new code has been sent" }`.

### Login
`POST /auth/login` · public

```json
{ "email": "maria@example.com", "password": "Patient123", "playerId": "onesignal-player-id" }
```

**200**

```json
{
  "success": true,
  "message": "Login successful",
  "statusCode": 200,
  "data": {
    "accessToken": "eyJhbGciOi…",
    "refreshToken": "eyJhbGciOi…",
    "jwtPayload": { "id": "6b066f4e46381fd9a0df2367", "profileId": "6b066f4e46381fd9a0df2369", "email": "maria@example.com", "role": "NORMALUSER" },
    "user": {
      "_id": "6b066f4e46381fd9a0df2367",
      "fullName": "Maria Papadopoulou",
      "email": "maria@example.com",
      "phone": "6900000001",
      "role": "NORMALUSER",
      "isBlocked": false,
      "isVerifyEmailOTPVerified": true,
      "language": "el",
      "notificationPreferences": { "appointments": true, "reminders": true, "insurance": true, "general": true },
      "privacyConsentAt": "2026-11-25T05:17:02.407Z",
      "lastLoginAt": "2026-11-25T05:17:02.570Z",
      "profileId": "6b066f4e46381fd9a0df2369",
      "profile": {
        "_id": "6b066f4e46381fd9a0df2369",
        "fullName": "Maria Papadopoulou",
        "dateOfBirth": "1990-05-01T00:00:00.000Z",
        "gender": "FEMALE",
        "bloodGroup": "A+",
        "membershipId": "HV-827E4255",
        "address": "Athens",
        "emergencyContact": "6900000009",
        "emergencyContacts": [{ "name": "Nikos Papadopoulos", "phone": "6900000009", "relation": "Brother" }],
        "allergies": ["penicillin"],
        "chronicConditions": ["asthma"]
      }
    },
    "profileData": { "…": "same as user.profile (kept for older clients)" }
  }
}
```

For a **provider**, `user.profile` holds the provider profile, including `approvalStatus`, `providerType` and `services`. See [getMe](#get-my-account).

Errors:
- `401 Invalid email or password`
- `403 Email is not verified…` (send the user to the OTP screen and call resend-otp)
- `403 Your account is blocked…`

### Refresh token
`POST /auth/refresh-token` · public

```json
{ "refreshToken": "eyJhbGciOi…" }
```

**200** `{ "data": { "accessToken": "eyJhbGciOi…" } }`

### Logout
`POST /auth/logout` · 🔒 any role

```json
{ "playerId": "onesignal-player-id" }
```

**200** `{ "data": { "message": "Logged out" } }`. Delete the stored tokens on the device afterwards.

### Forgot password (3 steps)

| Step | Endpoint | Body | Response `data` |
|---|---|---|---|
| 1 | `POST /auth/forgot-password` | `{ "email" }` | `{ "message": "If this email is registered, a reset code has been sent" }` |
| 2 | `POST /auth/verify-otp` | `{ "email", "otp": "123456" }` | `{ "message": "Code verified. You can now set a new password." }` |
| 3 | `POST /auth/reset-password` | `{ "email", "newPassword" }` (min 8) | `{ "accessToken", "refreshToken" }` → user is logged in |

Step 3 must happen within 10 minutes of step 1.

### Change password
`POST /auth/change-password` · 🔒 any role

```json
{ "oldPassword": "Patient123", "newPassword": "NewPass123" }
```

**200** `{ "data": { "accessToken": "…", "refreshToken": "…" } }`. **Replace the stored tokens**, because the old ones stop working.

---

## 7. Profile & settings

### Get my account
`GET /user/getMe` · 🔒 any role

This returns the same `user` object as login, with `profile` filled in for the role.

Provider profile example:

```json
{
  "data": {
    "_id": "6b066f4e46381fd9a0df238e",
    "fullName": "Dr. Giorgos Ioannou",
    "role": "PROVIDER",
    "profileId": "6b066f4e46381fd9a0df2390",
    "profile": {
      "_id": "6b066f4e46381fd9a0df2390",
      "fullName": "Dr. Giorgos Ioannou",
      "providerTypeId": "6b066f4e46381fd9a0df235e",
      "serviceId": ["6b066f4e46381fd9a0df2362"],
      "about": "Cardiologist",
      "address": "Vas. Sofias 10, Athens",
      "location": "Athens",
      "identification_images": "uploads/private/6b066f4e46381fd9a0df238e/identification/1795583822780-f68e….png",
      "specialization": "Cardiology",
      "medicalLicenseNumber": "LIC-12345",
      "yearsOfExperience": 12,
      "languages": ["Greek", "English"],
      "approvalStatus": "APPROVED",
      "isVerified": true,
      "isActive": true,
      "approvedAt": "2026-11-25T05:17:02.867Z",
      "providerType": { "_id": "6b066f4e46381fd9a0df235e", "key": "DOCTOR", "label": "DOCTOR" },
      "services": [{ "_id": "6b066f4e46381fd9a0df2362", "providerType": "DOCTOR", "title": "General consultation", "price": 40 }]
    }
  }
}
```

`approvalStatus` is `PENDING`, `APPROVED` or `REJECTED`. When it's `REJECTED`, `rejectionReason` explains why.

### Update my profile
`PATCH /user/updateMe` · 🔒 any role · JSON **or** multipart (`data` + `profile_image`)

Send only the fields you want to change. Unknown fields are rejected with `400`.

| Role | Allowed fields |
|---|---|
| NORMALUSER | `fullName, phone, dateOfBirth, gender, bloodGroup, address, emergencyContact, emergencyContacts, identificationNumber, allergies, chronicConditions` |
| PROVIDER | `fullName, phone, displayName, about, address, location, specialization, yearsOfExperience, languages, serviceId` |

```json
{ "address": "Thessaloniki", "allergies": ["penicillin", "nuts"] }
```

**200** returns the updated **profile** object. A new `profile_image` comes back as a CloudFront URL, and the old image is deleted.

### Settings (language & notification preferences)
`PATCH /user/settings` · 🔒 any role

```json
{ "language": "en", "notificationPreferences": { "reminders": true, "general": false } }
```

**200**

```json
{ "data": { "_id": "…", "language": "en", "notificationPreferences": { "appointments": true, "reminders": true, "insurance": true, "general": false } } }
```

A preference set to `false` switches off the **push** alert for that category. The in-app notification is still stored.

| Key | Covers |
|---|---|
| `appointments` | Appointment requests, updates and 24-hour reminders |
| `reminders` | Medication reminders |
| `insurance` | Insurance expiry |
| `general` | Announcements, document moderation, support replies |

---

## 8. Patient home & health card

### Home dashboard
`GET /normal-User/home` · 🔒 NORMALUSER

```json
{
  "data": {
    "profile": { "_id": "…", "fullName": "Maria P.", "bloodGroup": "A+", "membershipId": "HV-827E4255", "profile_image": "https://…/profile/1795583822601-me.png" },
    "healthCard": { "membershipId": "HV-827E4255", "bloodGroup": "A+" },
    "reminders": {
      "today": [
        { "reminderId": "…", "pillName": "Aspirin", "dosage": "100mg", "instructions": "After food", "assignedTo": "SELF", "time": "08:00", "scheduledAt": "2026-11-25T06:00:00.000Z", "status": "UPCOMING" }
      ],
      "remaining": 2,
      "taken": 0
    },
    "upcomingAppointments": [
      {
        "_id": "…",
        "appointmentDateTime": "2026-11-30T08:00:00.000Z",
        "status": "CONFIRMED",
        "reasonForVisit": "Chest pain when running",
        "provider": { "_id": "…", "fullName": "Dr. Giorgos Ioannou", "address": "Vas. Sofias 10, Athens", "specialization": "Cardiology" },
        "service": { "_id": "…", "title": "General consultation", "price": 40 }
      }
    ],
    "latestHealthLog": { "systolic": 120, "diastolic": 80, "heartRate": 72, "weight": 65.5, "bloodSugar": 95, "recordedAt": "2026-11-25T05:17:03.014Z" },
    "expiringInsurances": [ { "_id": "…", "forWhom": "SELF", "name": "Family health plan", "insuranceProvider": "Interamerican", "expiryDate": "2026-12-15T00:00:00.000Z" } ],
    "unreadNotifications": 1,
    "activeSos": null
  }
}
```

- `upcomingAppointments` holds the next 3.
- `expiringInsurances` lists insurances that expire within 30 days.
- `activeSos` is `{ _id, createdAt }` while an SOS alert is active, otherwise `null`.

### Digital health card
`GET /normal-User/health-card` · 🔒 NORMALUSER

```json
{
  "data": {
    "name": "Maria P.",
    "membershipId": "HV-827E4255",
    "dateOfBirth": "1990-05-01T00:00:00.000Z",
    "gender": "FEMALE",
    "bloodGroup": "A+",
    "allergies": ["penicillin"],
    "chronicConditions": ["asthma"],
    "emergencyContacts": [{ "name": "Nikos Papadopoulos", "phone": "6900000009", "relation": "Brother" }],
    "phone": "6900000001",
    "insurance": { "_id": "…", "name": "Family health plan", "number": "POL-778899", "insuranceProvider": "Interamerican", "expiryDate": "2026-12-15T00:00:00.000Z" },
    "profile_image": "https://…/profile/…png",
    "qrCode": "data:image/png;base64,iVBORw0KGgo…"
  }
}
```

- `qrCode` is a PNG data URL, ready to display: `Image.memory(base64Decode(qrCode.split(',')[1]))`.
- The QR contains the essential card info as JSON (`t: "HV-CARD"`), so it can be read offline.
- `insurance` is the patient's own insurance (SELF) with the nearest expiry date that hasn't passed, or `null`.

---

## 9. Provider directory & favorites

### Provider types
`GET /provider-types` · public → `data: [ { "_id", "key": "DOCTOR", "label": "DOCTOR", "isActive": true } ]`

### Search providers
`GET /provider/all-providers` · public · paginated

| Query | Example | Notes |
|---|---|---|
| searchTerm | `giorgos` | name, display name, specialization, address, location |
| providerTypeId | `6b066f4e…` | |
| providerType | `DOCTOR` | type key (alternative to the id) |
| specialization | `cardio` | partial match |
| location | `athens` | city / address partial match |
| language | `english` | |
| serviceId | `6b066f4e…` | offers this service |
| sortBy | `newest` \| `name` \| `experience` | default `newest` |
| page, limit | `1`, `10` | |

Only approved, active and unblocked providers are returned.

```json
{
  "data": {
    "meta": { "page": 1, "limit": 10, "total": 1, "totalPage": 1 },
    "data": [
      {
        "_id": "6b066f4e46381fd9a0df2390",
        "fullName": "Dr. Giorgos Ioannou",
        "displayName": null,
        "profile_image": "https://…",
        "about": "Cardiologist with 12 years of experience",
        "address": "Vas. Sofias 10, Athens",
        "location": "Athens",
        "specialization": "Cardiology",
        "yearsOfExperience": 12,
        "languages": ["Greek", "English"],
        "providerType": { "_id": "…", "key": "DOCTOR", "label": "DOCTOR" },
        "services": [{ "_id": "6b066f4e46381fd9a0df2362", "title": "General consultation", "price": 40 }]
      }
    ]
  }
}
```

### Provider details
`GET /provider/:providerId` · public

This returns everything above, plus:

```json
"availabilityDays": [
  { "_id": "…", "dayOfWeek": "MON", "availabilitySlots": [{ "_id": "…", "startTime": "09:00", "endTime": "13:00" }] }
],
"account": { "_id": "…", "email": "dr.giorgos@example.com", "phone": "6900000002", "isBlocked": false }
```

### Provider availability
`GET /availability-day/provider-availability/:providerId` · public → `data: [ { _id, dayOfWeek, availabilitySlots: [{ _id, startTime, endTime }] } ]`

Use this to build the booking calendar.
- Days are `MON`…`SUN`.
- Times are Greek local time.
- If the list is **empty**, the provider accepts any time.

### Favorites · 🔒 NORMALUSER

| Method | Path | Response |
|---|---|---|
| POST | `/favorite/:providerId` | **201** `{ _id, normalUserId, providerId }` · `409 Already in favorites` |
| GET | `/favorite/my-favorites` | `data: [ { _id, providerId, createdAt, provider: { _id, fullName, profile_image, specialization, address, location, providerType } } ]` |
| DELETE | `/favorite/:providerId` | **200** · `404 Favorite not found` |

---

## 10. Appointments

Appointment `status` moves through these values: `PENDING` → `CONFIRMED` → `COMPLETED`, or `CANCELLED` at any point before it's completed.

### Book (patient)
`POST /appointment/create-appointment` · 🔒 NORMALUSER

```json
{
  "providerId": "6b066f4e46381fd9a0df2390",
  "serviceId": "6b066f4e46381fd9a0df2362",
  "reasonForVisit": "Chest pain when running",
  "appointmentDateTime": "2026-11-30T08:00:00.000Z"
}
```

The server checks these rules:
- The time must be at least 5 minutes in the future.
- The provider must be approved.
- The service must be one the provider offers.
- If the provider has availability set, the time must fall inside a slot (Greek time).
- No other active booking can exist at that exact time.

**201** returns the joined appointment:

```json
{
  "data": {
    "_id": "6b066f4e46381fd9a0df23cb",
    "normalUserId": "…",
    "providerId": "…",
    "serviceId": "…",
    "reasonForVisit": "Chest pain when running",
    "appointmentDateTime": "2026-11-30T08:00:00.000Z",
    "durationMinutes": 30,
    "status": "PENDING",
    "isActive": true,
    "createdAt": "2026-11-25T05:17:02.944Z",
    "normalUser": { "_id": "…", "fullName": "Maria P.", "dateOfBirth": "1990-05-01T00:00:00.000Z", "gender": "FEMALE", "bloodGroup": "A+", "profile_image": "https://…", "email": "maria@example.com", "phone": "6900000001" },
    "provider": { "_id": "…", "fullName": "Dr. Giorgos Ioannou", "address": "Vas. Sofias 10, Athens", "location": "Athens", "specialization": "Cardiology", "providerType": { "key": "DOCTOR", "label": "DOCTOR" }, "email": "dr.giorgos@example.com", "phone": "6900000002" },
    "service": { "_id": "…", "title": "General consultation", "price": 40 }
  }
}
```

Errors:
- `409 This time slot is already booked. Please choose another time.`
- `400 The provider is not available at the selected time`
- `400 Provider not found or not available`
- `400 The provider does not offer the selected service`

### My appointments (patient)
`GET /appointment/my-appointments` · 🔒 NORMALUSER · paginated · each item has the same joined shape as above

| Query | Values |
|---|---|
| status | `upcoming` (active and in the future, sorted soonest first) · `past` · `active` · `PENDING` · `CONFIRMED` · `COMPLETED` · `CANCELLED` · omit for all |
| from, to | ISO dates (filter on `appointmentDateTime`) |
| searchTerm | provider name, service, reason |

`GET /appointment/my-appointments/:id` returns one appointment in the same shape.

### Cancel (patient)
`PATCH /appointment/cancel/:id` · 🔒 NORMALUSER

```json
{ "cancellationReason": "Feeling better" }
```

**200** returns the appointment with `"status": "CANCELLED"`, `"cancelledBy": "PATIENT"` and `"isActive": false`. Only `PENDING` and `CONFIRMED` appointments can be cancelled. The provider is notified.

### Add to calendar
`GET /appointment/my-appointments/:id/calendar.ics` · 🔒 NORMALUSER

This returns an iCalendar file (`text/calendar`) with a 1-hour alarm. Open it or share it so the phone's calendar app imports it. You can also create the event natively from the appointment fields.

### Provider: appointment list / detail
- `GET /appointment/provider-appointments` (🔒 PROVIDER) takes the same `status` / `from` / `to` / `searchTerm` / pagination params as the patient list.
- `GET /appointment/provider-appointments/:id` returns one appointment.
- `normalUser` includes the patient's name, contact details, date of birth and blood group.

### Provider: change status
`PATCH /appointment/provider-update-status/:id` · 🔒 PROVIDER

```json
{ "status": "CONFIRMED" }
```

```json
{ "status": "CANCELLED", "cancellationReason": "Doctor unavailable" }
```

| Current status | Can change to |
|---|---|
| PENDING | CONFIRMED, CANCELLED, COMPLETED |
| CONFIRMED | COMPLETED, CANCELLED |

**200** returns the appointment (without the joined objects). The patient gets a push and an in-app notification. A disallowed change returns `400 Cannot change a … appointment to …`.

The **24-hour reminder** is automatic: the patient gets a push about 24 hours before the appointment.

---

## 11. Medication reminders & adherence

### Create reminder
`POST /reminder/create-reminder` · 🔒 NORMALUSER · JSON or multipart (`data` + `prescription_file`)

| Field | Type | Required | Rules |
|---|---|---|---|
| pillName | string | ✅ | 1–100 |
| dosage | string | ✅ | e.g. `"500mg"`, `"1 tablet"` |
| schedule | string | ✅ | `Daily` \| `Weekly` \| `Monthly` |
| times | string[] | ✅ | `"HH:mm"` Greek time, 1–12 items |
| startDate | date | ✅ | `"2026-11-25"` |
| endDate | date | ✅ | ≥ startDate |
| scheduleMeta.dayOfWeek | number | Weekly | 0 = Sunday … 6 = Saturday |
| scheduleMeta.dayOfMonth | number | Monthly | 1–31 |
| instructions | string | | ≤ 500 |
| assignedTo | string | | `"SELF"` (default) or a family member name |
| isActive | boolean | | default `true` |

```json
{
  "pillName": "Aspirin",
  "dosage": "100mg",
  "schedule": "Daily",
  "times": ["08:00", "20:00"],
  "startDate": "2026-11-25",
  "endDate": "2026-12-25",
  "instructions": "After food",
  "assignedTo": "SELF"
}
```

**201**

```json
{
  "data": {
    "_id": "6b066f4e46381fd9a0df23eb",
    "pillName": "Aspirin",
    "dosage": "100mg",
    "schedule": "Daily",
    "times": ["08:00", "20:00"],
    "timesPerDay": 2,
    "startDate": "2026-11-25T00:00:00.000Z",
    "endDate": "2026-12-25T00:00:00.000Z",
    "instructions": "After food",
    "assignedTo": "SELF",
    "isActive": true,
    "prescription_file": "uploads/private/…/prescriptions/….pdf"
  }
}
```

The server sends a **push at each time** (Greek time). Its `data` is `{ reminderId, scheduledAt }`.

### List / update / delete

| Method | Path | Notes |
|---|---|---|
| GET | `/reminder/my-reminders` | `?isActive=true\|false` `?status=current\|ended` → array |
| PATCH | `/reminder/update-reminder/:id` | any create field (partial); multipart to replace the prescription |
| DELETE | `/reminder/delete-reminder/:id` | also deletes its dose history |

### Today's doses
`GET /reminder/today` · 🔒 NORMALUSER

```json
{
  "data": [
    { "reminderId": "6b066f4e46381fd9a0df23eb", "pillName": "Aspirin", "dosage": "100mg", "instructions": "After food", "assignedTo": "SELF", "time": "08:00", "scheduledAt": "2026-11-25T06:00:00.000Z", "status": "UPCOMING" }
  ]
}
```

| status | Meaning |
|---|---|
| `UPCOMING` | Time not reached yet |
| `PENDING` | Time passed, not confirmed yet |
| `TAKEN` / `SKIPPED` | Confirmed by the user |
| `MISSED` | Not confirmed within 2 hours (set automatically) |

### Record a dose (taken / skipped)
`POST /reminder/:reminderId/intake` · 🔒 NORMALUSER

```json
{ "scheduledAt": "2026-11-25T06:00:00.000Z", "status": "TAKEN" }
```

- `status` is `TAKEN`, `SKIPPED` or `MISSED`. `note` (≤ 300 chars) is optional.
- `scheduledAt` must be one of the reminder's scheduled times. Take it from `/reminder/today` or from the push `data`.
- You can record a dose at most 1 hour early.
- Sending it again updates the existing record.

**200**

```json
{ "data": { "_id": "…", "reminderId": "…", "scheduledAt": "2026-11-25T06:00:00.000Z", "status": "TAKEN", "takenAt": "2026-11-25T06:03:10.000Z" } }
```

### Adherence history
`GET /reminder/adherence?from=2026-11-01&to=2026-11-30&reminderId=&page=1&limit=20` · 🔒 NORMALUSER (the default range is the last 30 days)

```json
{
  "data": {
    "range": { "from": "2026-10-26T05:17:03.003Z", "to": "2026-11-25T05:17:03.003Z" },
    "summary": { "taken": 1, "missed": 0, "skipped": 0, "pending": 0, "adherenceRate": 100 },
    "byReminder": [ { "reminderId": "…", "pillName": "Aspirin", "dosage": "100mg", "taken": 1, "missed": 0, "skipped": 0, "pending": 0, "adherenceRate": 100 } ],
    "history": {
      "meta": { "page": 1, "limit": 20, "total": 1, "totalPage": 1 },
      "data": [ { "_id": "…", "reminderId": "…", "scheduledAt": "2026-11-24T22:00:00.000Z", "status": "TAKEN", "takenAt": "2026-11-25T05:17:02.995Z", "reminder": { "pillName": "Aspirin", "dosage": "100mg" } } ]
    },
    "totalRecords": 1
  }
}
```

`adherenceRate` is a percentage: taken ÷ (taken + missed + skipped). It's `null` when there's no data yet.

---

## 12. Health logs

### Add a log
`POST /healthLog/create` · 🔒 NORMALUSER

At least one measurement is required.

| Field | Type | Range / notes |
|---|---|---|
| forWhom | string | `SELF` (default) \| `FAMILY` |
| familyMemberName | string | required for FAMILY |
| recordedAt | date | default now; not in the future |
| bloodPressure | string | `"120/80"` (split into systolic/diastolic) |
| systolic / diastolic | number | 40–300 / 20–200 mmHg |
| heartRate | number | 20–300 bpm |
| weight | number | 0.5–500 kg |
| bloodSugar | number | 10–1000 mg/dL |
| temperature | number | 30–45 °C |
| oxygenSaturation | number | 50–100 % |
| note | string | ≤ 500 |

```json
{ "forWhom": "SELF", "bloodPressure": "120/80", "heartRate": 72, "weight": 65.5, "bloodSugar": 95 }
```

**201**

```json
{ "data": { "_id": "…", "forWhom": "SELF", "recordedAt": "2026-11-25T05:17:03.014Z", "systolic": 120, "diastolic": 80, "heartRate": 72, "weight": 65.5, "bloodSugar": 95 } }
```

### List
`GET /healthLog?forWhom=SELF&from=&to=&page=1&limit=30` · paginated, newest first.

### Graph data (trends)
`GET /healthLog/trends?forWhom=SELF&metrics=systolic,diastolic,weight&groupBy=day&from=&to=`

- `groupBy` is `day`, `week` or `month`.
- `metrics` is any of `systolic, diastolic, heartRate, weight, bloodSugar, temperature, oxygenSaturation`. Leave it out to get all of them.
- The default range is the last 30 days.

```json
{
  "data": {
    "range": { "from": "2026-10-26T05:17:03.023Z", "to": "2026-11-25T05:17:03.023Z" },
    "groupBy": "day",
    "metrics": ["systolic", "diastolic", "weight"],
    "points": [
      {
        "period": "2026-11-24T22:00:00.000Z",
        "count": 1,
        "systolic": { "avg": 120, "min": 120, "max": 120 },
        "diastolic": { "avg": 80, "min": 80, "max": 80 },
        "weight": { "avg": 65.5, "min": 65.5, "max": 65.5 }
      }
    ]
  }
}
```

`period` is the start of the day, week or month in Greek time. A metric's value is `null` when nothing was recorded in that period.

### Update / delete
`PATCH /healthLog/:id` (any field, partial) · `DELETE /healthLog/:id`

---

## 13. Insurance

### Create
`POST /insurance/create` · 🔒 NORMALUSER · multipart (`data` + optional `insurance_Photo`) or JSON

| Field | Required | Notes |
|---|---|---|
| forWhom | ✅ | `SELF` \| `FAMILY` |
| familyMemberName | FAMILY | |
| name | ✅ | plan name |
| number | ✅ | policy number |
| insuranceProvider | ✅ | company |
| expiryDate | ✅ | date |
| coverageType | | |
| startDate | | |
| reminderEnabled | | default `true` (expiry push 30, 7 and 1 days before, at 09:00) |

**201**

```json
{
  "data": {
    "_id": "6b066f4f46381fd9a0df2403",
    "forWhom": "SELF",
    "name": "Family health plan",
    "number": "POL-778899",
    "insuranceProvider": "Interamerican",
    "coverageType": "Hospital",
    "expiryDate": "2026-12-15T00:00:00.000Z",
    "insurance_Photo": "uploads/private/6b066f4e46381fd9a0df2367/insurance/1795583823027-2be3….png",
    "reminderEnabled": true
  }
}
```

### List
`GET /insurance?forWhom=SELF` (or `FAMILY`; leave it out for all) → array sorted by expiry. Each item adds `"isExpired": false, "daysToExpiry": 20`. An empty list returns `[]`, not an error.

### Update / delete
- `PATCH /insurance/:id`: partial fields; send multipart to replace the photo. Changing `expiryDate` restarts the expiry reminders.
- `DELETE /insurance/:id`

---

## 14. Medical documents vault

### Upload (1–5 files)
`POST /medicalDocument` · 🔒 NORMALUSER · multipart

```
data     = {"title":"Blood test March","category":"LAB_RESULT","tags":["blood","annual"],"forWhom":"SELF","documentDate":"2026-03-10"}
document = <file 1>
document = <file 2>   (optional, up to 5)
```

| `data` field | Notes |
|---|---|
| title | optional; defaults to the file name. With several files it becomes "Title (1)", "Title (2)"… |
| category | `PRESCRIPTION` · `LAB_RESULT` · `IMAGING` · `VACCINATION` · `REPORT` · `OTHER` |
| tags | max 15, each ≤ 30 chars, stored lowercase and de-duplicated |
| forWhom | `SELF` \| `FAMILY` (`familyMemberName` required for FAMILY) |
| documentDate | date shown on the document |

**201** (an array, with one item per file):

```json
{
  "data": [
    {
      "_id": "6b066f4f46381fd9a0df2408",
      "title": "Blood test March",
      "category": "LAB_RESULT",
      "tags": ["blood", "annual"],
      "forWhom": "SELF",
      "documentDate": "2026-03-10T00:00:00.000Z",
      "file": "uploads/private/6b066f4e46381fd9a0df2367/documents/1795583823038-532b….pdf",
      "fileType": "application/pdf",
      "fileSize": 245761,
      "status": "PENDING",
      "createdAt": "2026-11-25T05:17:03.041Z"
    }
  ]
}
```

`status` is the admin moderation state: `PENDING`, `APPROVED` or `REJECTED`. When it's `REJECTED`, `moderationNote` holds the reason. The user is notified when it changes. Files can be viewed whatever the status.

### List / tags / details

| Method | Path | Notes |
|---|---|---|
| GET | `/medicalDocument/my` | paginated (default 20). Filters: `tag`, `category`, `forWhom`, `status`, `searchTerm`. Each item has `isShared: true/false` |
| GET | `/medicalDocument/my/tags` | `[ { "tag": "blood", "count": 3 } ]` – for filter chips |
| GET | `/medicalDocument/my/:id` | one document |
| PATCH | `/medicalDocument/:id` | `{ title?, category?, tags?, forWhom?, familyMemberName?, documentDate? }` |
| DELETE | `/medicalDocument/:id` | deletes the file |

To view a file: `GET {SERVER_URL}/{file}` with the Authorization header (see [§3](#3-files--images)).

### Share with a doctor (time-limited link)
`POST /medicalDocument/:id/share` · 🔒 NORMALUSER

```json
{ "expiresInHours": 48 }
```

`expiresInHours` ranges from 1 to 720 and defaults to 72.

**200**

```json
{
  "data": {
    "documentId": "6b066f4f46381fd9a0df2408",
    "title": "Blood test March",
    "shareUrl": "https://api.yourdomain.com/api/v1/medicalDocument/shared/WqDlcnRz2f4yS2J8IvjF5ShOMUIVMt3I",
    "expiresAt": "2026-11-27T05:17:03.058Z"
  }
}
```

- Share `shareUrl` with the phone's share sheet. **Anyone with the link can open the file until it expires**, without logging in.
- A new share replaces the old link.
- To stop sharing early, call `DELETE /medicalDocument/:id/share`, which returns `{ "_id": "…", "isShared": false }`.

---

## 15. SOS / emergency

The phone handles the actual emergency actions **natively**: calling 112 or 166, sending the SMS to contacts, and getting GPS. The API stores the alert, alerts the support team live, and gives you the numbers, contacts and share text.

### Emergency info (cache for offline)
`GET /sos/emergency-info` · 🔒 NORMALUSER

```json
{
  "data": {
    "emergencyNumbers": [
      { "name": "European emergency number", "number": "112" },
      { "name": "Ambulance (EKAB)", "number": "166" },
      { "name": "Police", "number": "100" },
      { "name": "Fire service", "number": "199" },
      { "name": "Coast guard", "number": "108" },
      { "name": "Poison center", "number": "2107793777" }
    ],
    "emergencyContacts": [{ "name": "Nikos Papadopoulos", "phone": "6900000009", "relation": "Brother" }],
    "medicalInfo": { "bloodGroup": "A+", "allergies": ["penicillin"], "chronicConditions": ["asthma"] }
  }
}
```

### Trigger SOS
`POST /sos` · 🔒 NORMALUSER

All fields are optional, but `latitude` and `longitude` must be sent together.

```json
{ "latitude": 37.9755, "longitude": 23.7348, "accuracy": 12, "address": "Syntagma Square, Athens", "message": "Chest pain" }
```

**201**

```json
{
  "data": {
    "alert": {
      "_id": "6b066f4f7beafa516b6dfbfa",
      "status": "ACTIVE",
      "location": { "type": "Point", "coordinates": [23.7348, 37.9755] },
      "address": "Syntagma Square, Athens",
      "accuracy": 12,
      "message": "Chest pain",
      "createdAt": "2026-11-25T05:17:03.101Z"
    },
    "mapsLink": "https://maps.google.com/?q=37.9755,23.7348",
    "shareMessage": "SOS! Maria P. needs help. Location: https://maps.google.com/?q=37.9755,23.7348 (Syntagma Square, Athens)",
    "emergencyNumbers": [ { "name": "European emergency number", "number": "112" } ],
    "emergencyContacts": [ { "name": "Nikos Papadopoulos", "phone": "6900000009", "relation": "Brother" } ]
  }
}
```

- `location.coordinates` is in **[longitude, latitude]** order (GeoJSON).
- Send `shareMessage` by SMS or the share sheet to `emergencyContacts`.
- Pressing SOS again while an alert is active updates the same alert; it doesn't create a new one.

### Live location / cancel / history

| Method | Path | Body | Notes |
|---|---|---|---|
| PATCH | `/sos/:id/location` | `{ "latitude", "longitude", "accuracy?", "address?" }` | send every ~30 s while active |
| PATCH | `/sos/:id/cancel` | — | false alarm → `status: "CANCELLED"` |
| GET | `/sos/my` | — | last 50 alerts |

When the support team resolves an alert, its status becomes `RESOLVED`. `404 No active SOS alert` means the alert was already closed.

---

## 16. Support chat

This works for both patients and providers (🔒 NORMALUSER / PROVIDER). Each user has one conversation with the support team.

### Open chat / load messages
`GET /support/my-conversation?limit=30&before=<ISO date>`

```json
{
  "data": {
    "conversation": { "_id": "6b066f4f7beafa516b6dfc05", "status": "OPEN", "unreadByUser": 0, "lastMessage": "Hello, I cannot upload my PDF", "lastMessageAt": "2026-11-25T05:17:03.136Z" },
    "messages": [
      { "_id": "…", "conversation": "…", "sender": "6b066f4e46381fd9a0df2367", "senderRole": "NORMALUSER", "text": "Hello, I cannot upload my PDF", "createdAt": "2026-11-25T05:17:03.136Z" }
    ],
    "hasMore": false
  }
}
```

- `messages` come **newest first**; reverse them for display.
- To load older messages, pass `before` = the `createdAt` of the oldest message you already have.
- Opening the chat marks the support team's replies as read.
- `senderRole: "ADMIN"` means the message came from the support team.

### Send message
`POST /support/messages`

```json
{ "text": "Hello, I cannot upload my PDF" }
```

`text` is 1–2000 characters. **201** returns the message.

New replies arrive through the socket event `support-message` and as a push (`data.conversationId`).

---

## 17. Notifications

### Notification object

```json
{
  "_id": "6b066f4e46381fd9a0df23e6",
  "user": "6b066f4e46381fd9a0df2367",
  "type": "APPOINTMENT",
  "title": "Appointment update",
  "message": "Your appointment on 30/11/2026 10:00 is confirmed.",
  "data": { "appointmentId": "6b066f4e46381fd9a0df23cb", "status": "CONFIRMED" },
  "isRead": false,
  "createdAt": "2026-11-25T05:17:02.974Z"
}
```

`type` is one of `APPOINTMENT`, `MEDICATION`, `INSURANCE`, `PROVIDER`, `DOCUMENT`, `SOS`, `SUPPORT` or `GENERAL`. For the `data` keys, see [§5](#5-realtime-socketio--push-onesignal).

### Endpoints · 🔒 any role

| Method | Path | Response `data` |
|---|---|---|
| GET | `/notification/get-notifications?page=1&limit=20&isRead=false&type=APPOINTMENT` | `{ meta: { …, unreadCount }, data: [notification] }` |
| GET | `/notification/unread-count` | `{ "unreadCount": 3 }` (badge) |
| PATCH | `/notification/read/:id` | the notification with `isRead: true` |
| PATCH | `/notification/see-notifications` | `{ "modified": 3 }` (mark all read) |
| DELETE | `/notification/delete-notification/:id` | deleted notification |

Notifications are kept for 1 year.

---

## 18. Provider app: services & availability

All routes in this section need the 🔒 PROVIDER role.

### Services

| Method | Path | Body | Notes |
|---|---|---|---|
| GET | `/service/admin-service/{TYPE_KEY}` | — | Catalogue services for the type (public). Add their ids to your profile with `PATCH /user/updateMe { "serviceId": [...] }` |
| POST | `/service/create-service` | `{ "title": "ECG test", "price": 25 }` | Creates **your own** service and adds it to your profile automatically |
| GET | `/service/my-created-service` | — | Your own services (array) |
| PATCH | `/service/update-service/:id` | `{ "title"?, "price"? }` | |
| DELETE | `/service/delete-service/:id` | — | Removes it from your profile |

Service object:

```json
{ "_id": "6b066f4e46381fd9a0df23a4", "providerId": "6b066f4e46381fd9a0df2390", "providerType": "DOCTOR", "isAdminCreated": false, "title": "ECG test", "price": 25, "isDeleted": false }
```

### Weekly availability

| Method | Path | Body | Notes |
|---|---|---|---|
| POST | `/availability-day/create-availability-day` | `{ "dayOfWeek": "MON" }` | `MON TUE WED THU FRI SAT SUN`; `409` if the day exists |
| GET | `/availability-day/my-availability-days` | — | `[ { _id, dayOfWeek, availabilitySlots: [{ _id, startTime, endTime }] } ]` |
| DELETE | `/availability-day/:dayId` | — | deletes the day and its slots |
| POST | `/availability-slot/create-availability-slot` | `{ "availabilityDayId", "startTime": "09:00", "endTime": "13:00" }` | `HH:mm`, end > start, no overlap (`409`) |
| DELETE | `/availability-slot/delete-availability-slot/:slotId` | — | |

Patients can only book times that fall inside these slots, in Greek time. With no availability set, any time is accepted.

---

## 19. Content (articles, FAQ, legal)

All public.

| Method | Path | Response `data` |
|---|---|---|
| GET | `/article?searchTerm=&page=1&limit=10` | paginated `[ { _id, title, details (HTML), article_image (URL), createdAt } ]` |
| GET | `/article/:id` | one article |
| GET | `/manage-web/get-faq` | `[ { _id, question, answer } ]` |
| GET | `/manage-web/get-about-us` | `{ _id, description (HTML) }` |
| GET | `/manage-web/get-terms-conditions` | `{ _id, description (HTML) }` |
| GET | `/manage-web/get-privacy-policy` | `{ _id, description (HTML) }` |

The `description` and `details` fields contain HTML; render them with an HTML widget. About, Terms and Privacy return `data: null` until the admin writes them, so show a placeholder in that case.

---

## 20. Enums & limits

| Name | Values |
|---|---|
| role | `NORMALUSER`, `PROVIDER` |
| gender | `MALE`, `FEMALE`, `OTHER` |
| bloodGroup | `A+`, `A-`, `B+`, `B-`, `AB+`, `AB-`, `O+`, `O-` |
| language | `en`, `el` |
| forWhom | `SELF`, `FAMILY` |
| appointment status | `PENDING`, `CONFIRMED`, `COMPLETED`, `CANCELLED` |
| provider approvalStatus | `PENDING`, `APPROVED`, `REJECTED` |
| reminder schedule | `Daily`, `Weekly`, `Monthly` |
| dose status | `UPCOMING` (today list only), `PENDING`, `TAKEN`, `SKIPPED`, `MISSED` |
| document category | `PRESCRIPTION`, `LAB_RESULT`, `IMAGING`, `VACCINATION`, `REPORT`, `OTHER` |
| document status | `PENDING`, `APPROVED`, `REJECTED` |
| SOS status | `ACTIVE`, `RESOLVED`, `CANCELLED` |
| dayOfWeek | `MON`, `TUE`, `WED`, `THU`, `FRI`, `SAT`, `SUN` |
| notification type | `APPOINTMENT`, `MEDICATION`, `INSURANCE`, `PROVIDER`, `DOCUMENT`, `SOS`, `SUPPORT`, `GENERAL` |

| Limit | Value |
|---|---|
| Password | 8–128 characters |
| OTP | 6 digits, valid 10 min, max 5 wrong attempts |
| Upload size | 10 MB per file |
| Page size | default 10 (documents/notifications 20, health logs 30), max 100 |
| Access / refresh token | 1 day / 30 days |
| Missed dose | marked automatically 2 h after the scheduled time |

---

## 21. GDPR (export / delete account)

### Download my data
`GET /user/export-my-data` · 🔒 any role

This returns a JSON object with everything stored about the user:
- `account` and `profile`
- `appointments`, `reminders`, `medicationIntakes`, `healthLogs`
- `insurances`, `documents`, `favorites`, `sosAlerts`
- `notifications` and `supportMessages`

Offer it as a downloadable or shareable `.json` file.

### Delete my account
`DELETE /auth/delete-me` · 🔒 any role

```json
{ "password": "Patient123" }
```

**200** `{ "data": { "message": "Your account and all related data were permanently deleted" } }`

This **cannot be undone**. All records and files are deleted, so show a confirmation dialog first. A wrong password returns `400 Password is incorrect`.

---

### Quick checklist for the app

- [ ] Store `accessToken` and `refreshToken` securely; refresh on `401`.
- [ ] Send the OneSignal `playerId` on login; send it again on logout.
- [ ] Use multipart with a `data` JSON field for every upload.
- [ ] Private files: add the `Authorization` header to image and file requests.
- [ ] Show `message` from error responses; use `error[].path` to highlight form fields.
- [ ] Connect Socket.io with the access token for live notifications and support chat.
- [ ] Convert UTC dates to local time; reminder times and slots are Greek time (`HH:mm`).
- [ ] Use push `data` (`appointmentId`, `reminderId`, …) to open the right screen.
