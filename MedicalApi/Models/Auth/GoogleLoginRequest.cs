using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace Models.Auth
{
    public class GoogleLoginRequest
    {
        [Required(ErrorMessage = "Google ID token is required")]
        public string IdToken { get; set; } = string.Empty;
        [Required(ErrorMessage = "Google ID token is required")]
        public int RoleId { get; set; }
    }
}
