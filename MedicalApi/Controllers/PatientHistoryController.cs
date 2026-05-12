using IServices;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Models.Patient;
using MedicalApi.Exceptions;

namespace MedicalApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Policy = "RequireVerifiedAccount")]
    public class PatientHistoryController : ControllerBase
    {
        private readonly IPatientService _historyService;

        public PatientHistoryController(IPatientService historyService)
        {
            _historyService = historyService;
        }

        [HttpPost("medical")]
        public async Task<IActionResult> CreateMedicalHistory([FromBody] PatientMedicalHistoryModel model)
        {
            int newId = await _historyService.CreateMedicalHistoryAsync(model);
            return Ok(new { Message = "Medical history created successfully.", Id = newId });
        }

        [HttpPost("surgical")]
        public async Task<IActionResult> CreateSurgicalHistory([FromBody] PatientSurgicalHistoryModel model)
        {
            int newId = await _historyService.CreateSurgicalHistoryAsync(model);
            return Ok(new { Message = "Surgical history created successfully.", Id = newId });
        }

        [HttpPost("drug")]
        public async Task<IActionResult> CreateDrugHistory([FromBody] PatientDrugHistoryModel model)
        {
            int newId = await _historyService.CreateDrugHistoryAsync(model);
            return Ok(new { Message = "Drug history created successfully.", Id = newId });
        }

        [HttpPost("lifestyle")]
        public async Task<IActionResult> CreateBaselineLifestyle([FromBody] PatientBaselineLifestyleModel model)
        {
            await _historyService.CreateBaselineLifestyleAsync(model);
            return Ok(new { Message = "Baseline lifestyle created successfully." });
        }

        [HttpPut("medical/{id}")]
        public async Task<IActionResult> UpdateMedicalHistory(int id, [FromBody] PatientMedicalHistoryModel model)
        {
            model.Id = id; // Force the ID to ensure an update happens
            await _historyService.UpdateMedicalHistoryAsync(model);
            return Ok(new { Message = "Medical history updated successfully.", Id = id });
        }

        [HttpPut("surgical/{id}")]
        public async Task<IActionResult> UpdateSurgicalHistory(int id, [FromBody] PatientSurgicalHistoryModel model)
        {
            model.Id = id;
            await _historyService.UpdateSurgicalHistoryAsync(model);
            return Ok(new { Message = "Surgical history updated successfully.", Id = id });
        }

        [HttpPut("drug/{id}")]
        public async Task<IActionResult> UpdateDrugHistory(int id, [FromBody] PatientDrugHistoryModel model)
        {
            model.Id = id;
            await _historyService.UpdateDrugHistoryAsync(model);
            return Ok(new { Message = "Drug history updated successfully.", Id = id });
        }

        // NOTE: Lifestyle doesn't need an {id} in the URL because it is 1-to-1 with the PatientId
        [HttpPut("lifestyle/{patientId}")]
        public async Task<IActionResult> UpdateBaselineLifestyle(string patientId, [FromBody] PatientBaselineLifestyleModel model)
        {
            model.PatientId = patientId;
            await _historyService.UpdateBaselineLifestyleAsync(model);
            return Ok(new { Message = "Baseline lifestyle updated successfully." });
        }
    }
}