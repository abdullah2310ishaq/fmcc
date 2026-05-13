using IServices;
using MedicalApi.Exceptions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MedicalApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Policy = "RequireVerifiedAccount")]
    public class HealthWorkerDashboardController : ControllerBase
    {
        private readonly IHealthWorkerService _dashboardService;
        private readonly ILogger<HealthWorkerDashboardController> _logger;

        public HealthWorkerDashboardController(IHealthWorkerService dashboardService, ILogger<HealthWorkerDashboardController> logger)
        {
            _dashboardService = dashboardService;
            _logger = logger;
        }

        /// <summary>
        /// Retrieves the top-level KPI statistics for the Health Worker's dashboard.
        /// </summary>
        [HttpGet("{healthWorkerId}/stats")]
        public async Task<IActionResult> GetStats([FromRoute] string healthWorkerId)
        {
            _logger.LogInformation("GetStats attempt: HealthWorkerId={HealthWorkerId}", healthWorkerId ?? "Unknown");

            if (string.IsNullOrWhiteSpace(healthWorkerId))
            {
                throw new ValidationException("HealthWorkerId is required.");
            }

            var stats = await _dashboardService.GetStatsAsync(healthWorkerId);

            if (stats == null)
            {
                throw new NotFoundException("Dashboard statistics not found.");
            }

            _logger.LogInformation("GetStats success: HealthWorkerId={HealthWorkerId}", healthWorkerId);
            return Ok(stats);
        }

        /// <summary>
        /// Retrieves a prioritized list of patients requiring immediate follow-ups.
        /// </summary>
        [HttpGet("{healthWorkerId}/followups")]
        public async Task<IActionResult> GetFollowUps([FromRoute] string healthWorkerId)
        {
            _logger.LogInformation("GetFollowUps attempt: HealthWorkerId={HealthWorkerId}", healthWorkerId ?? "Unknown");

            if (string.IsNullOrWhiteSpace(healthWorkerId))
            {
                throw new ValidationException("HealthWorkerId is required.");
            }

            var followUps = await _dashboardService.GetFollowUpsAsync(healthWorkerId);

            _logger.LogInformation("GetFollowUps success: HealthWorkerId={HealthWorkerId}", healthWorkerId);
            return Ok(followUps);
        }

        /// <summary>
        /// Retrieves the complete directory of all patients assigned to the Health Worker.
        /// </summary>
        [HttpGet("{healthWorkerId}/patients")]
        public async Task<IActionResult> GetAllPatients([FromRoute] string healthWorkerId)
        {
            _logger.LogInformation("GetAllPatients attempt: HealthWorkerId={HealthWorkerId}", healthWorkerId ?? "Unknown");

            if (string.IsNullOrWhiteSpace(healthWorkerId))
            {
                throw new ValidationException("HealthWorkerId is required.");
            }

            var patients = await _dashboardService.GetAllPatientsAsync(healthWorkerId);

            _logger.LogInformation("GetAllPatients success: HealthWorkerId={HealthWorkerId}", healthWorkerId);
            return Ok(patients);
        }
    }
}