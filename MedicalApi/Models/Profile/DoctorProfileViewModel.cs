using System;

namespace Models.Profile
{
    public class DoctorProfileViewModel
    {
        // User Info
        public string UserId { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string ProfileImageUrl { get; set; } = string.Empty;
        public bool IsVerified { get; set; }
        public DateTime JoinedDate { get; set; }

        // Doctor Info
        public string DoctorId { get; set; } = string.Empty;
        public string Gender { get; set; } = string.Empty;
        public DateOnly? DateOfBirth { get; set; } = null;
        public string CNIC { get; set; } = string.Empty;
        public string PMDCNumber { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public decimal FeePerPatient { get; set; }

        // Lookups (IDs and Names)
        public int? SpecialtyId { get; set; }
        public string SpecialtyName { get; set; } = string.Empty;

        public int? ProvinceId { get; set; }
        public string ProvinceName { get; set; } = string.Empty;

        public int? DistrictId { get; set; }
        public string DistrictName { get; set; } = string.Empty;

        public int? TehsilId { get; set; }
        public string TehsilName { get; set; } = string.Empty;
    }
}