using System;
using System.Collections.Generic;
using System.Text;

namespace Models.Auth
{
    public class TokenRequestModel
    {
        public string AccessToken { get; set; } = string.Empty;
        public string RefreshToken { get; set; } = string.Empty;
    }
}
