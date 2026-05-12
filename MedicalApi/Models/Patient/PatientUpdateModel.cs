using System;
using System.Collections.Generic;
using System.Text;
using System.Text.Json.Serialization;

namespace Models.Patient
{

    public class PatientUpdateModel
    {
        public string Id { get; set; } = string.Empty;
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Gender { get; set; }
        public DateTime? DateOfBirth { get; set; }
        public int? MaritalStatusId { get; set; }

        [JsonPropertyName("cnic")]
        public string? CNIC { get; set; }

        public string? ContactNumber { get; set; }
        public string? Address { get; set; }
        public string? AssignedHealthWorkerId { get; set; }
        public int? ProvinceId { get; set; }
        public int? DistrictId { get; set; }
        public int? TehsilId { get; set; }
    }
}
