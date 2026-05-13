using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace Models.Auth
{
    public class GoogleWebLoginRequest
    {
        [Required(ErrorMessage = "Google access token is required")]
        public string AccessToken { get; set; } = string.Empty;
        [Required(ErrorMessage = "Google access token is required")]
        public int RoleId { get; set; }
    }
}
