using System;
using System.Collections.Generic;
using System.Text;

namespace Models.Reference
{
    public class TehsilModel
    {
        public int Id { get; set; }
        public string TehsilName { get; set; } = string.Empty;
        public int DistrictId { get; set; }
        public int ProvinceId { get; set; }
    }
}
