using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text;

namespace Models.Users
{
    public class DoctorRequestModel
    {
        public string UserId { get; set; } = string.Empty;
        public char Gender { get; set; }
        public DateOnly DateOfBirth { get; set; }
        public string CNIC { get; set; } = string.Empty;
        public int DoctorSpecialtyId { get; set; }
        public string PMDCNumber { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public int ProvinceId { get; set; }
        public int DistrictId { get; set; }
        public int TehsilId { get; set; }
    }
}
