using System;
using System.Collections.Generic;
using System.Text;

namespace Models.Users
{
    public class HealthWorkerRequestModel
    {
        public string UserId { get; set; } = string.Empty;
        public char Gender { get; set; }
        public DateOnly DateOfBirth { get; set; }
        public string CNIC { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public int EducationLevelId { get; set; }
        public int ProvinceId { get; set; }
        public int DistrictId { get; set; }
        public int TehsilId { get; set; }
        public int ApproxPatientsPerDay { get; set; }
    }
}
