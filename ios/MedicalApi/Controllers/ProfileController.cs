using IServices;
using MedicalApi.Exceptions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Models.Profile;
using System;
using System.Threading.Tasks;

namespace MedicalApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Policy = "RequireVerifiedAccount")]
    public class ProfileController : ControllerBase
    {
        private readonly IProfileService _profileService;
        private readonly ILogger<ProfileController> _logger;

        public ProfileController(IProfileService profileService, ILogger<ProfileController> logger)
        {
            _profileService = profileService;
            _logger = logger;
        }

        /// <summary>
        /// Gets the profile information for a doctor.
        /// </summary>
        [HttpGet("doctor-profile/{userId}")]
        public async Task<IActionResult> GetDoctorProfile([FromRoute] string userId)
        {
            _logger.LogInformation("GetDoctorProfile attempt: UserId={UserId}", userId ?? "Unknown");

            if (string.IsNullOrWhiteSpace(userId))
            {
                throw new ValidationException("UserId is required.");
            }

            var profile = await _profileService.GetDoctorProfileAsync(userId);

            if (profile == null)
            {
                throw new NotFoundException("Doctor profile not found.");
            }

            _logger.LogInformation("GetDoctorProfile success: UserId={UserId}", userId);
            return Ok(profile);
        }

        /// <summary>
        /// Updates the profile information for a doctor.
        /// </summary>
        [HttpPut("doctor-profile")]
        public async Task<IActionResult> UpdateDoctorProfile([FromBody] DoctorProfileUpdateModel model)
        {
            _logger.LogInformation("UpdateDoctorProfile attempt: UserId={UserId}", model?.UserId ?? "Unknown");

            // 1. Basic Request Validation
            if (model == null)
            {
                throw new ValidationException("Request body is required.");
            }

            if (string.IsNullOrWhiteSpace(model.UserId))
            {
                throw new ValidationException("UserId is required.");
            }

            // 2. Execute Business Logic
            var result = await _profileService.UpdateDoctorProfileAsync(model);

            if (!result)
            {
                throw new ValidationException("Failed to update doctor profile.");
            }

            // 3. Success Path
            _logger.LogInformation("UpdateDoctorProfile success: UserId={UserId}", model.UserId);
            return Ok("Doctor profile updated successfully.");
        }

        /// <summary>
        /// Updates the profile information for a Health Worker.
        /// </summary>
        [HttpPut("healthworker-profile")]
        public async Task<IActionResult> UpdateHealthWorkerProfile([FromBody] HealthWorkerProfileUpdateModel model)
        {
            _logger.LogInformation("UpdateHealthWorkerProfile attempt: UserId={UserId}", model?.UserId ?? "Unknown");

            // 1. Basic Request Validation
            if (model == null)
            {
                throw new ValidationException("Request body is required.");
            }

            if (string.IsNullOrWhiteSpace(model.UserId))
            {
                throw new ValidationException("UserId is required.");
            }

            // 2. Execute Business Logic via Service Layer
            var result = await _profileService.UpdateHealthWorkerProfileAsync(model);

            if (!result)
            {
                throw new ValidationException("Failed to update health worker profile.");
            }

            // 3. Success Path
            _logger.LogInformation("UpdateHealthWorkerProfile success: UserId={UserId}", model.UserId);
            return Ok("Health worker profile updated successfully.");
        }

        /// <summary>
        /// Gets the profile information for a health worker.
        /// </summary>
        [HttpGet("health-worker-profile/{userId}")]
        public async Task<IActionResult> GetHealthWorkerProfile([FromRoute] string userId)
        {
            _logger.LogInformation("GetHealthWorkerProfile attempt: UserId={UserId}", userId ?? "Unknown");

            if (string.IsNullOrWhiteSpace(userId))
            {
                throw new ValidationException("UserId is required.");
            }

            var profile = await _profileService.GetHealthWorkerProfileByUserIdAsync(userId);

            if (profile == null)
            {
                throw new NotFoundException("Health worker profile not found.");
            }

            _logger.LogInformation("GetHealthWorkerProfile success: UserId={UserId}", userId);
            return Ok(profile);
        }
    }
}