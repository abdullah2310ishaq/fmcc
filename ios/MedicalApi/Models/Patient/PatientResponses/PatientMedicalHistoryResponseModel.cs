using System;
using System.Collections.Generic;
using System.Text;

namespace Models.Patient.PatientResponses
{
    public class PatientMedicalHistoryResponseModel
    {
        public int Id { get; set; }
        public string PatientId { get; set; } = string.Empty;
        public int ConditionId { get; set; }
        public string ConditionName { get; set; } = string.Empty;
        public int? DurationInMonths { get; set; }
        public bool IsOnMedication { get; set; }
        public int? ComplianceLevelId { get; set; }
        public string ComplianceLevelName { get; set; } = string.Empty;
    }
}
