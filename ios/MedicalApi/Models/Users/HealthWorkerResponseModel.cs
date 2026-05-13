using System;
using System.Collections.Generic;
using System.Text;

namespace Models.Users
{
    public class HealthWorkerResponseModel : UserBaseModel
    {
        public int EducationLevelId { get; set; }
        public string LHWTrainingCertificate { get; set; } = string.Empty;
        public string Address { get; set; } = string.Empty;
    }
}
