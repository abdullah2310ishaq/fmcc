using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace Models.Patient
{
    public class PatientMedicalHistoryModel
    {
        public int? Id { get; set; } = null;
        [Required] public string PatientId { get; set; } = string.Empty;
        [Required] public int ConditionId { get; set; }
        public short? DurationInMonths { get; set; }
        public bool IsOnMedication { get; set; }
        public int? ComplianceLevelId { get; set; }
    }
}
