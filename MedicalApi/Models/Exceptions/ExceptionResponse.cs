using System;
using System.Collections.Generic;
using System.Text;

namespace Models.Exceptions
{
    public class ExceptionResponse
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public int StatusCode { get; set; }
        public string TraceId { get; set; } = string.Empty;
    }
}
