using System;
using System.Collections.Generic;
using System.Text;

namespace Models.Users
{
    public class DoctorResponseModel : UserBaseModel
    {
        public string DoctorSpeciality { get; set; } = string.Empty;
        public string PMDCNumber { get; set; } = string.Empty;
    }
}
