using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace Models.Patient
{
    public class PatientBaselineLifestyleModel
    {
        [Required] public string PatientId { get; set; } = string.Empty;
        public bool FamilyHistoryOfHTNOrStroke { get; set; }
        public bool TobaccoUse { get; set; }
    }
}
