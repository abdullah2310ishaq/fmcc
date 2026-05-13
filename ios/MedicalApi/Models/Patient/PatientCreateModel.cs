using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;
using System.Text.Json.Serialization;

namespace Models.Patient
{

    public class PatientCreateModel
    {
        [Required(ErrorMessage = "First name is required")]
        [StringLength(50, MinimumLength = 2, ErrorMessage = "First name must be between 2 and 50 characters")]
        public string FirstName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Last name is required")]
        public string LastName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Gender is required")]
        public string Gender { get; set; } = string.Empty;

        [Required(ErrorMessage = "Date of Birth is required")]
        [DataType(DataType.Date)]
        public DateTime? DateOfBirth { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Please select a valid Marital Status")]
        public int MaritalStatusId { get; set; }

        [JsonPropertyName("cnic")]
        [RegularExpression(@"^\d{5}-\d{7}-\d{1}$", ErrorMessage = "CNIC must be in the format 12345-1234567-1")]
        public string? CNIC { get; set; }

        [Required(ErrorMessage = "Contact number is required")]
        [Phone(ErrorMessage = "Invalid phone number format")]
        public string ContactNumber { get; set; } = string.Empty;

        [Required(ErrorMessage = "Address is required")]
        public string Address { get; set; } = string.Empty;

        [Display(Name = "Health Worker")]
        public string? AssignedHealthWorkerId { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Please select a valid Province")]
        public int? ProvinceId { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Please select a valid District")]
        public int? DistrictId { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Please select a valid Tehsil")]
        public int? TehsilId { get; set; }
    }
}
