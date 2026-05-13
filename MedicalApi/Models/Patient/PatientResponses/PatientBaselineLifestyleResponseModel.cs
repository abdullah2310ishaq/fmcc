using System;
using System.Collections.Generic;
using System.Text;

namespace Models.Patient.PatientResponses
{
    public class PatientBaselineLifestyleResponseModel
    {
        public string PatientId { get; set; } = string.Empty;
        public bool FamilyHistoryOfHTNOrStroke { get; set; }
        public bool TobaccoUse { get; set; }
    }
}
