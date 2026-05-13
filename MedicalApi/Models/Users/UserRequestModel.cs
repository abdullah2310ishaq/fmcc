using System;
using System.Collections.Generic;
using System.Text;

namespace Models.Users
{
    public class UserRequestModel
    {
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string? ProfilePictureUrl { get; set; } = string.Empty;
        public int RoleId { get; set; }
    }
}
