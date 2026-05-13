using System;
using System.Collections.Generic;
using System.Text;

namespace Models.Patient.PatientResponses
{
    public class PatientCompleteHistoryResponseModel
    {
        public PatientBaselineLifestyleResponseModel? BaselineLifestyle { get; set; }
        public List<PatientMedicalHistoryResponseModel> MedicalHistory { get; set; } = new();
        public List<PatientSurgicalHistoryResponseModel> SurgicalHistory { get; set; } = new();
        public List<PatientDrugHistoryResponseModel> DrugHistory { get; set; } = new();
    }
}
