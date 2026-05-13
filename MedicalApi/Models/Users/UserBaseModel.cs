using System;
using System.Collections.Generic;
using System.Text;

namespace Models.Users
{
    public class UserBaseModel
    {
        public string? UserId { get; set; } = string.Empty;
        public string? ProfessionalId { get; set; } = string.Empty; //doctor or lhw Id
        public string? FirstName { get; set; } = string.Empty;
        public string? LastName { get; set; } = string.Empty;
        public string? Email { get; set; } = string.Empty;
        public int RoleId { get; set; }
        public bool IsVerified { get; set; }
        public string? ProfileImageUrl { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public string? RefreshToken { get; set; }
        public DateTime? RefreshTokenExpiryTime { get; set; }
    }
}
