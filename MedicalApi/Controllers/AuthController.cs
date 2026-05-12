using IServices.Auth;
using MedicalApi.Exceptions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Models.Auth;

namespace MedicalApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly IJwtService _jwtService;
        private readonly ILogger<AuthController> _logger;

        public AuthController(IJwtService jwtService, ILogger<AuthController> logger)
        {
            _jwtService = jwtService;
            _logger = logger;
        }


        /// <summary>
        /// Mobile flow: receives a Google ID token (JWT) for server-side validation.
        /// </summary>
        [HttpPost("google-login")]
        public async Task<ActionResult<UserLoginResponse>> LoginUserAsync([FromBody] GoogleLoginRequest request)
        {
            _logger.LogInformation("GoogleLogin: Token present={HasToken}", !string.IsNullOrWhiteSpace(request?.IdToken));

            if (request == null)
            {
                throw new ValidationException("Request body is required.");
            }

            if (string.IsNullOrWhiteSpace(request.IdToken))
            {
                throw new ValidationException("Google ID token is required.");
            }

            var user = await _jwtService.AuthenticateUser(request.IdToken, request.RoleId);

            if (user == null)
            {
                throw new UnauthorizedException("Authentication failed.");
            }

            _logger.LogInformation("GoogleLogin success: UserId={UserId}, Email={Email}", user.UserId, user.Email);
            return Ok(user);
        }

        /// <summary>
        /// Web flow: receives a Google access token (OAuth2) and verifies via Google's userinfo API.
        /// </summary>
        [HttpPost("google-login-web")]
        public async Task<ActionResult<UserLoginResponse>> LoginUserWebAsync([FromBody] GoogleWebLoginRequest request)
        {
            _logger.LogInformation("GoogleLoginWeb: Token present={HasToken}", !string.IsNullOrWhiteSpace(request?.AccessToken));

            if (request == null)
            {
                throw new ValidationException("Request body is required.");
            }

            if (string.IsNullOrWhiteSpace(request.AccessToken))
            {
                throw new ValidationException("Google access token is required.");
            }

            var user = await _jwtService.AuthenticateUserWithAccessToken(request.AccessToken, request.RoleId);

            if (user == null)
            {
                throw new UnauthorizedException("Authentication failed.");
            }

            _logger.LogInformation("GoogleLoginWeb success: UserId={UserId}, Email={Email}", user.UserId, user.Email);
            return Ok(user);
        }

        [HttpPost("refresh-token")]
        public async Task<IActionResult> Refresh([FromBody] TokenRequestModel model)
        {
            _logger.LogInformation("Refresh Token attempt");

            if (model == null)
            {
                throw new ValidationException("Request body is required.");
            }

            if (string.IsNullOrWhiteSpace(model.AccessToken) || string.IsNullOrWhiteSpace(model.RefreshToken))
            {
                throw new ValidationException("AccessToken and RefreshToken are required.");
            }

            var response = await _jwtService.RefreshTokensAsync(model);

            if (response == null)
            {
                throw new UnauthorizedException("Session expired. Please log in again.");
            }

            _logger.LogInformation("Refresh Token success");
            return Ok(response);
        }
    }
}
