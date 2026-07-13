# Doctor App (CareHo)

Flutter mobile app for Lady Health Workers and Doctors. API base URL: `https://aphasia.careho.pk` (see `lib/src/core/network/api_config.dart`).

OpenAPI spec: [`MedicalApi.postman_collection.json`](MedicalApi.postman_collection.json)

## Doctor module — API audit (app wiring)

| Method | Path | App (`DoctorApi` / `Endpoints`) | Notes |
|--------|------|----------------------------------|-------|
| `GET` | `/api/Doctor/{doctorId}` | `getDoctor` | Full doctor profile (name, email, PMDC, specialty, location) |
| `GET` | `/api/Doctor/{doctorId}/dashboard` | `getDashboard` | Metrics: `emergencyQueueCount`, `patientsSeenToday`, `earningsToday`, `prescriptionsWrittenToday` |
| `GET` | `/api/Doctor/{doctorId}/prescriptions` | `getDoctorPrescriptions` | Doctor prescription list |
| **`POST`** | `/api/Doctor/prescription` | **`createPrescription`** | **Create** — `PrescriptionSubmitRequest` |
| **`PUT`** | `/api/Doctor/prescription` | **`updatePrescription`** | **Edit** — `PrescriptionEditRequest` |
| `POST` | `/api/Doctor/{doctorId}/unassign-hospital` | `unassignHospital` | Hospital confirmation “No” |
| `GET` | `/api/Patient/emergency-queue/{doctorId}` | `getEmergencyQueue` | Assigned patient queue (`visitActionId` 3=Normal, 4=Emergency) |
| `GET` | `/api/Patient/prescription-history/{patientId}` | `getPatientPrescriptionHistory` | LHW read-only history |

### Create prescription (`POST`)

Body (`PrescriptionSubmitModel`):

- `visitId`, `patientId`, `doctorId` (string)
- `tenureInDays` (int)
- `doctorNotes` (string)
- `continuedFromPrescriptionId` (string, optional)
- `nextVisitDate` (datetime, optional)
- `medicines[]`: `medicineId`, `customMedicineName`, `dosageAmount`, `frequency`, `durationInDays`

### Edit prescription (`PUT`)

Body (`PrescriptionEditModel`):

- `prescriptionId`, `doctorId` (string)
- `tenureInDays` (int)
- `doctorNotes` (string)
- `continuedFromPrescriptionId` (string, optional)
- `medicines[]` (same shape as create)

### Known backend issues

- `emergencyQueueCount` on dashboard may not match queue list; the app counts emergencies from `GET /api/Patient/emergency-queue/{doctorId}` using each row’s `visitActionId`.

## Project structure (doctor)

- `lib/src/features/doctor/api/doctor_api.dart` — HTTP layer
- `lib/src/features/doctor/models/doctor_models.dart` — request/response models
- `lib/src/features/doctor/controllers/` — Provider `ChangeNotifier`s
- `lib/src/features/doctor/screens/` — UI screens

Use `ApiClient` only (no ad-hoc `Dio()`). Paths live in `lib/src/core/network/endpoints.dart`.
