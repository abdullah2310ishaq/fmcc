using System;
using System.Collections.Generic;
using System.Text;

namespace Models.Profile
{
    public class HealthWorkerProfileModel
    {
        // User Base Info
        public string UserId { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string ProfileImageUrl { get; set; } = string.Empty;
        public bool IsVerified { get; set; }
        public DateTime JoinedDate { get; set; }

        // HealthWorker Specific Info
        public string HealthWorkerId { get; set; } = string.Empty;
        public string Gender { get; set; } = string.Empty;
        public DateOnly? DateOfBirth { get; set; }
        public string CNIC { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public string LHWTrainingCertificate { get; set; } = string.Empty;
        public string Address { get; set; } = string.Empty;
        public int ApproxPatientsPerDay { get; set; }
        public decimal Salary { get; set; }

        // Education Lookup
        public int? EducationLevelId { get; set; }
        public string EducationLevel { get; set; } = string.Empty;

        // Location Lookups
        public int? ProvinceId { get; set; }
        public string ProvinceName { get; set; } = string.Empty;
        public int? DistrictId { get; set; }
        public string DistrictName { get; set; } = string.Empty;
        public int? TehsilId { get; set; }
        public string TehsilName { get; set; } = string.Empty;
    }
}
