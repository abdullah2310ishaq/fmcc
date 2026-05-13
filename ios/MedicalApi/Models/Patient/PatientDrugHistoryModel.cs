using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace Models.Patient
{
    public class PatientDrugHistoryModel
    {
        public int? Id { get; set; } = null;
        [Required] public string PatientId { get; set; } = string.Empty;
        [Required] public int MedicineCategoryId { get; set; }
        public int? AdherenceLevelId { get; set; }
        public string? SideEffects { get; set; }
    }
}
