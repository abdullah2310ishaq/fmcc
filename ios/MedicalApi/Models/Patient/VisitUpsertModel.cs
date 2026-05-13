using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace Models.Patient
{
    public class VisitUpsertModel
    {
        // Visit Core
        public string? Id { get; set; } = null;
        [Required] public string PatientId { get; set; } = string.Empty;
        [Required] public string HealthWorkerId { get; set; } = string.Empty;
        [Required]
        [Range(1, int.MaxValue)]
        public int VisitTypeId { get; set; }
        public bool IsFollowUpVisit { get; set; }
        public string? ReasonForVisit { get; set; }

        // Vitals (Ensure UI respects constraints: BP 50-300 / Pulse 20-300)
        [Range(50, 300)] public int? SystolicBP1 { get; set; }
        [Range(50, 300)] public int? DiastolicBP1 { get; set; }
        [Range(50, 300)] public int? SystolicBP2 { get; set; }
        [Range(50, 300)] public int? DiastolicBP2 { get; set; }
        [Range(50, 300)] public int? AvgSystolicBP { get; set; }
        [Range(50, 300)] public int? AvgDiastolicBP { get; set; }
        [Range(20, 300)] public int? Pulse { get; set; }

        // Actions & Status
        public int? VisitActionId { get; set; }
        public int? VisitStatusId { get; set; }
        public string? MedicalAdherenceNote { get; set; }
        public DateTime? NextVisitDate { get; set; }

        // Lifestyle Assessment
        public bool HighSaltDiet { get; set; }
        public int? PhysicalActivityLevelId { get; set; }
        public string? WeightConcerns { get; set; }
        public bool AlcoholUse { get; set; }

        // Selected Symptoms
        public List<int> SymptomIds { get; set; } = new List<int>();
    }
}
