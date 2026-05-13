using System;
using System.Collections.Generic;
using System.Text;

namespace Models.Profile
{
    public class HealthWorkerProfileUpdateModel
    {
        public string UserId { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Gender { get; set; } = string.Empty;
        public DateOnly DateOfBirth { get; set; }
        public string CNIC { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public int EducationLevelId { get; set; }
        public string LHWTrainingCertificate { get; set; } = string.Empty;
        public int ProvinceId { get; set; }
        public int DistrictId { get; set; }
        public int TehsilId { get; set; }
        public string Address { get; set; } = string.Empty;
    }
}
