using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace Models.Patient
{
    public class PatientSurgicalHistoryModel
    {
        public int? Id { get; set; } = null;
        [Required] public string PatientId { get; set; } = string.Empty;
        [Required] public int ProcedureId { get; set; }
        public byte? ApproxMonth { get; set; }
        public short? ApproxYear { get; set; }
        public string? Notes { get; set; }
    }
}
