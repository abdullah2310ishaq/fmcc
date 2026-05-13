using System;
using System.Collections.Generic;
using System.Text;

namespace Models.Patient.PatientResponses
{
    public class PatientDrugHistoryResponseModel
    {
        public int Id { get; set; }
        public string PatientId { get; set; } = string.Empty;
        public int MedicineCategoryId { get; set; }
        public string CategoryName { get; set; } = string.Empty;
        public int? AdherenceLevelId { get; set; }
        public string AdherenceLevelName { get; set; } = string.Empty;
        public string SideEffects { get; set; } = string.Empty;
        public string MedicineCategoryName { get; set; }
    }
}
