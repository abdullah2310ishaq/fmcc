using System;
using System.Collections.Generic;
using System.Text;

namespace Models.Auth
{
    public class UserLoginResponse
    {
        public string UserId { get; set; } = string.Empty;
        public string ProfessionId { get; set; } = string.Empty;
        public string? RoleName { get; set; }
        public string AccessToken { get; set; } = string.Empty;
        public int ExpiresIn { get; set; }
        public bool IsVerified { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? ProfileImageUrl { get; set; }
        public string? Email { get; set; }
        public string RefreshToken { get; set; } = string.Empty;
    }
}
