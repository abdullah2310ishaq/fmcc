using IServices;
using Models.Patient;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using MedicalApi.Exceptions;

namespace MedicalApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Policy = "RequireVerifiedAccount")]
    public class PatientController : ControllerBase
    {
        private readonly IPatientService _patientService;

        public PatientController(IPatientService patientService)
        {
            _patientService = patientService;
        }

        // ==========================================
        // PATIENT CORE ENDPOINTS
        // ==========================================

        [HttpGet("{patientId}")]
        public async Task<IActionResult> GetPatientProfile(string patientId)
        {
            if (string.IsNullOrWhiteSpace(patientId))
                throw new ValidationException("PatientId is required.");

            var result = await _patientService.GetPatientProfileByIdAsync(patientId);
            if (result != null)
                return Ok(result);
            else
                throw new NotFoundException("Patient not found");
        }

        [HttpPost]
        public async Task<IActionResult> CreatePatient([FromBody] PatientCreateModel model)
        {
            var result = await _patientService.CreatePatientAsync(model);
            if (result != null)
            {
                return Ok(new { Message = "Patient created successfully.", Data = result });
            }
            throw new ValidationException("Failed to create patient.");
        }

        [HttpPut]
        public async Task<IActionResult> UpdatePatient([FromBody] PatientUpdateModel model)
        {
            var result = await _patientService.UpdatePatientAsync(model);
            if (result != null)
            {
                return Ok(new { Message = "Patient updated successfully.", Data = result });
            }
            throw new ValidationException("Failed to update patient.");
        }

        // ==========================================
        // PATIENT MEDICAL HISTORY ENDPOINTS
        // ==========================================


        [HttpGet("complete-history/{patientId}")]
        public async Task<IActionResult> GetCompleteHistory(string patientId)
        {
            if (string.IsNullOrWhiteSpace(patientId))
                throw new ValidationException("PatientId is required.");

            var result = await _patientService.GetCompleteHistoryAsync(patientId);
            if (result.BaselineLifestyle is null
                || result.MedicalHistory is null
                || result.SurgicalHistory is null
                || result.DrugHistory is null)
                throw new NotFoundException("History not found");

            return Ok(result);
        }

        //[HttpGet("medicalhistory/{patientId}")]
        //public async Task<IActionResult> GetMedicalHistory(string patientId)
        //{
        //    if (string.IsNullOrWhiteSpace(patientId))
        //        throw new ValidationException("PatientId is required.");

        //    var result = await _patientService.GetMedicalHistoryAsync(patientId);
        //    if (result.Count > 0)
        //        return Ok(new { Message = "Medical history fetched successfully.", Data = result });
        //    else
        //        throw new NotFoundException("Patient not found");
        //}

        [HttpPost("medicalhistory")]
        public async Task<IActionResult> CreateMedicalHistory([FromBody] PatientMedicalHistoryModel model)
        {
            if (model is null)
                throw new ValidationException("Object can't be null");
            var result = await _patientService.CreateMedicalHistoryAsync(model);
            if (result > 0)
                return Ok(new { Message = "Medical history created successfully.", Data = result });
            throw new ValidationException("Failed to create medical history.");
        }

        [HttpPut("medicalhistory")]
        public async Task<IActionResult> UpdateMedicalHistory([FromBody] PatientMedicalHistoryModel model)
        {
            var result = await _patientService.UpdateMedicalHistoryAsync(model);
            if (result > 0)
                return Ok(new { Message = "Medical history updated successfully.", Data = result });
            throw new ValidationException("Failed to update medical history.");
        }

        // ==========================================
        // PATIENT SURGICAL HISTORY ENDPOINTS
        // ==========================================

        //[HttpGet("surgicalhistory/{patientId}")]
        //public async Task<IActionResult> GetSurgicalHistory(string patientId)
        //{
        //    if (string.IsNullOrWhiteSpace(patientId))
        //        throw new ValidationException("PatientId is required.");

        //    var result = await _patientService.GetSurgicalHistoryAsync(patientId);
        //    return Ok(new { Message = "Surgical history fetched successfully.", Data = result });
        //}

        [HttpPost("surgicalhistory")]
        public async Task<IActionResult> CreateSurgicalHistory([FromBody] PatientSurgicalHistoryModel model)
        {
            var result = await _patientService.CreateSurgicalHistoryAsync(model);
            if (result > 0)
                return Ok(new { Message = "Surgical history created successfully.", Data = result });
            throw new ValidationException("Failed to create surgical history.");
        }

        [HttpPut("surgicalhistory")]
        public async Task<IActionResult> UpdateSurgicalHistory([FromBody] PatientSurgicalHistoryModel model)
        {
            var result = await _patientService.UpdateSurgicalHistoryAsync(model);
            if (result > 0)
                return Ok(new { Message = "Surgical history updated successfully.", Data = result });
            throw new ValidationException("Failed to update surgical history.");
        }

        // ==========================================
        // PATIENT DRUG HISTORY ENDPOINTS
        // ==========================================

        //[HttpGet("drughistory/{patientId}")]
        //public async Task<IActionResult> GetDrugHistory(string patientId)
        //{
        //    if (string.IsNullOrWhiteSpace(patientId))
        //        throw new ValidationException("PatientId is required.");

        //    var result = await _patientService.GetDrugHistoryAsync(patientId);
        //    return Ok(new { Message = "Drug history fetched successfully.", Data = result });
        //}

        [HttpPost("drughistory")]
        public async Task<IActionResult> CreateDrugHistory([FromBody] PatientDrugHistoryModel model)
        {
            var result = await _patientService.CreateDrugHistoryAsync(model);
            if (result > 0)
                return Ok(new { Message = "Drug history created successfully.", Data = result });
            throw new ValidationException("Failed to create drug history.");
        }

        [HttpPut("drughistory")]
        public async Task<IActionResult> UpdateDrugHistory([FromBody] PatientDrugHistoryModel model)
        {
            var result = await _patientService.UpdateDrugHistoryAsync(model);
            if (result > 0)
                return Ok(new { Message = "Drug history updated successfully.", Data = result });
            throw new ValidationException("Failed to update drug history.");
        }

        // ==========================================
        // PATIENT BASELINE LIFESTYLE ENDPOINTS
        // ==========================================

        //[HttpGet("baselinelifestyle/{patientId}")]
        //public async Task<IActionResult> GetBaselineLifestyle(string patientId)
        //{
        //    if (string.IsNullOrWhiteSpace(patientId))
        //        throw new ValidationException("PatientId is required.");

        //    var result = await _patientService.GetBaselineLifestyleAsync(patientId);

        //    if (result == null)
        //        return NotFound(new { Message = "Baseline lifestyle not found for this patient." });

        //    return Ok(new { Message = "Baseline lifestyle fetched successfully.", Data = result });
        //}

        [HttpPost("baselinelifestyle")]
        public async Task<IActionResult> CreateBaselineLifestyle([FromBody] PatientBaselineLifestyleModel model)
        {
            var result = await _patientService.CreateBaselineLifestyleAsync(model);
            if (result)
            {
                return Ok(new { Message = "Baseline lifestyle created successfully." });
            }
            throw new ValidationException("Failed to create baseline lifestyle.");
        }

        [HttpPut("baselinelifestyle")]
        public async Task<IActionResult> UpdateBaselineLifestyle([FromBody] PatientBaselineLifestyleModel model)
        {
            var result = await _patientService.UpdateBaselineLifestyleAsync(model);
            if (result)
            {
                return Ok(new { Message = "Baseline lifestyle updated successfully." });
            }
            throw new ValidationException("Failed to update baseline lifestyle.");
        }

        // ==========================================
        // PATIENT VISIT ENDPOINTS
        // ==========================================

        [HttpGet("visits/{patientId}/")]
        public async Task<IActionResult> GetPatientVisits(string patientId)
        {
            if (string.IsNullOrWhiteSpace(patientId))
                throw new ValidationException("PatientId is required.");

            var result = await _patientService.GetPatientVisitsAsync(patientId);
            return Ok(new { Message = "Patient visits fetched successfully.", Data = result });
        }

        [HttpPost("visit")]
        public async Task<IActionResult> CreateVisit([FromBody] VisitUpsertModel model)
        {
            model.Id = null;
            var newId = await _patientService.CreateVisitAsync(model);

            if (string.IsNullOrWhiteSpace(newId))
            {
                throw new ValidationException("Failed to record visit.");
            }

            return Ok(new { Message = "Visit recorded successfully.", VisitId = newId });
        }

        [HttpPut("visit")]
        public async Task<IActionResult> UpdateVisit([FromBody] VisitUpsertModel model)
        {
            if (string.IsNullOrWhiteSpace(model.Id))
                throw new ValidationException("Visit Id is required for updating.");

            var updatedId = await _patientService.UpdateVisitAsync(model);

            if (string.IsNullOrWhiteSpace(updatedId))
                throw new NotFoundException($"Visit with Id '{model.Id}' was not found.");

            return Ok(new { Message = "Visit updated successfully.", VisitId = updatedId });
        }
    }
}