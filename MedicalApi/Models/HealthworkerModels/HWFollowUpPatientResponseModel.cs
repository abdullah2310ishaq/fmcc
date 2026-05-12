using System;
using System.Collections.Generic;
using System.Text;

namespace Models.HealthworkerModels
{
    public class HWFollowUpPatientResponseModel
    {
        public string PatientId { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public int Age { get; set; }
        public string Gender { get; set; } = string.Empty;
        public string FormattedPatientId { get; set; } = string.Empty;
        public string LastVisitId { get; set; } = string.Empty;
        public DateTime LastVisitDate { get; set; }
        public string? LastVisitReason { get; set; }
        public int? SystolicBP1 { get; set; }
        public int? DiastolicBP1 { get; set; }
        public DateTime NextVisitDate { get; set; }
        public bool IsOverdue { get; set; }
        public string PrimaryCondition { get; set; } = string.Empty;

        // FIXED: Safe string splitting to prevent IndexOutOfRangeException
        public string Initials
        {
            get
            {
                if (string.IsNullOrWhiteSpace(FullName)) return "U";

                var tokens = FullName.Split(' ', StringSplitOptions.RemoveEmptyEntries);
                if (tokens.Length == 0) return "U";
                if (tokens.Length == 1) return tokens[0][0].ToString().ToUpper();

                return $"{tokens[0][0]}{tokens[1][0]}".ToUpper();
            }
        }
    }
}
