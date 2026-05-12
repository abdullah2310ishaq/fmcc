using System;
using System.Collections.Generic;
using System.Text;

namespace Models.Patient.PatientResponses
{
    public class PatientVisitResponseModel
    {
        public string VisitId { get; set; } = string.Empty;
        public string PatientId { get; set; } = string.Empty;
        public string HealthWorkerId { get; set; } = string.Empty;
        public DateTime VisitDate { get; set; }
        public int VisitTypeId { get; set; }
        public string VisitTypeName { get; set; } = string.Empty;
        public bool IsFollowUpVisit { get; set; }
        public string ReasonForVisit { get; set; } = string.Empty;
        public int? AvgSystolicBP { get; set; }
        public int? AvgDiastolicBP { get; set; }
        public int? Pulse { get; set; }
        public int? VisitActionId { get; set; }
        public string VisitActionName { get; set; } = string.Empty;
        public int? VisitStatusId { get; set; }
        public string VisitStatusName { get; set; } = string.Empty;
        public string MedicalAdherenceNote { get; set; } = string.Empty;
        public DateOnly? NextVisitDate { get; set; }
    }
}
