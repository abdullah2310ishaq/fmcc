using IServices;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System.Threading.Tasks;
using MedicalApi.Exceptions;

namespace MedicalApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Policy = "RequireVerifiedAccount")]
    public class ReferenceController : ControllerBase
    {
        private readonly IReferenceService _referenceService;
        private readonly ILogger<ReferenceController> _logger;

        public ReferenceController(
            IReferenceService referenceService,
            ILogger<ReferenceController> logger)
        {
            _referenceService = referenceService;
            _logger = logger;
        }

        // ====================================================
        // EXISTING DEMOGRAPHIC & LOCATION ENDPOINTS
        // ====================================================
        [HttpGet("education-levels")]
        public async Task<IActionResult> GetEducationLevels() => Ok(await _referenceService.GetEducationLevelsAsync());

        [HttpGet("provinces")]
        public async Task<IActionResult> GetProvinces() => Ok(await _referenceService.GetProvincesAsync());

        [HttpGet("districts/{provinceId}")]
        public async Task<IActionResult> GetDistricts([FromRoute] int provinceId) => Ok(await _referenceService.GetDistrictsByProvinceIdAsync(provinceId));

        [HttpGet("tehsils/{provinceId}/{districtId}")]
        public async Task<IActionResult> GetTehsils([FromRoute] int provinceId, [FromRoute] int districtId) => Ok(await _referenceService.GetTehsilsByProvinceAndDistrictIdAsync(provinceId, districtId));


        // ====================================================
        // NEW CLINICAL REFERENCE ENDPOINTS
        // ====================================================
        [HttpGet("marital-statuses")]
        public async Task<IActionResult> GetMaritalStatuses() => Ok(await _referenceService.GetMaritalStatusesAsync());

        [HttpGet("medical-conditions")]
        public async Task<IActionResult> GetMedicalConditions() => Ok(await _referenceService.GetMedicalConditionsAsync());

        [HttpGet("medicine-categories")]
        public async Task<IActionResult> GetMedicineCategories() => Ok(await _referenceService.GetMedicineCategoriesAsync());

        [HttpGet("surgical-procedures")]
        public async Task<IActionResult> GetSurgicalProcedures() => Ok(await _referenceService.GetSurgicalProceduresAsync());

        [HttpGet("symptoms")]
        public async Task<IActionResult> GetSymptoms() => Ok(await _referenceService.GetSymptomsAsync());

        [HttpGet("visit-actions")]
        public async Task<IActionResult> GetVisitActions() => Ok(await _referenceService.GetVisitActionsAsync());

        [HttpGet("visit-statuses")]
        public async Task<IActionResult> GetVisitStatuses() => Ok(await _referenceService.GetVisitStatusesAsync());

        [HttpGet("visit-types")]
        public async Task<IActionResult> GetVisitTypes() => Ok(await _referenceService.GetVisitTypesAsync());

        [HttpGet("physical-activity-levels")]
        public async Task<IActionResult> GetPhysicalActivityLevels() => Ok(await _referenceService.GetPhysicalActivityLevelsAsync());

        [HttpGet("adherence-levels")]
        public async Task<IActionResult> GetAdherenceLevels() => Ok(await _referenceService.GetAdherenceLevelsAsync());

        [HttpGet("compliance-levels")]
        public async Task<IActionResult> GetComplianceLevels() => Ok(await _referenceService.GetComplianceLevelsAsync());
    }
}