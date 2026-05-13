using System;
using System.Collections.Generic;
using System.Text;

namespace Models.Reference
{
    public class DistrictModel
    {
        public int Id { get; set; }
        public string DistrictName { get; set; } = string.Empty;
        public int ProvinceId { get; set; }
    }
}
