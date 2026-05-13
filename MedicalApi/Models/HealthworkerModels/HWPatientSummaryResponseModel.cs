using System;
using System.Collections.Generic;
using System.Text;

namespace Models.HealthworkerModels
{
    public class HWPatientSummaryResponseModel
    {
        public string PatientId { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public int Age { get; set; }
        public string Gender { get; set; } = string.Empty;
        public string FormattedPatientId { get; set; } = string.Empty;
        public string PrimaryCondition { get; set; } = string.Empty;
        public DateTime? LastVisitDate { get; set; }

        public string Initials => string.IsNullOrWhiteSpace(FullName) ? "U" :
            $"{FullName.Split(' ')[0][0]}{(FullName.Contains(' ') ? FullName.Split(' ')[1][0] : "")}".ToUpper();
    }
}
