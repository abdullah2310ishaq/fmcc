using System;
using System.Collections.Generic;
using System.Text;

namespace Models.Patient
{
    public class PatientProfileResponseModel
    {
        public string Id { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Gender { get; set; } = string.Empty;

        // Mapped safely to DateOnly!
        public DateOnly? DateOfBirth { get; set; }

        public int? MaritalStatusId { get; set; }
        public string MaritalStatusName { get; set; } = string.Empty;
        public string CNIC { get; set; } = string.Empty;
        public string ContactNumber { get; set; } = string.Empty;
        public string Address { get; set; } = string.Empty;
        public string AssignedHealthWorkerId { get; set; } = string.Empty;
        public int? ProvinceId { get; set; }
        public string ProvinceName { get; set; } = string.Empty;
        public int? DistrictId { get; set; }
        public string DistrictName { get; set; } = string.Empty;
        public int? TehsilId { get; set; }
        public string TehsilName { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public int PatientNumber { get; set; }
    }
}
