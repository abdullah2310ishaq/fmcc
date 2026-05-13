using System;
using System.Collections.Generic;
using System.Text;

namespace Models.Patient.PatientResponses
{
    public class PatientSurgicalHistoryResponseModel
    {
        public int Id { get; set; }
        public string PatientId { get; set; } = string.Empty;
        public int ProcedureId { get; set; }
        public string ProcedureName { get; set; } = string.Empty;
        public int? ApproxMonth { get; set; }
        public int? ApproxYear { get; set; }
        public string Notes { get; set; } = string.Empty;
    }
}
