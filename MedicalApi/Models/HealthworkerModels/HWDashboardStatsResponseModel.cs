using System;
using System.Collections.Generic;
using System.Text;

namespace Models.HealthworkerModels
{
    public class HWDashboardStatsResponseModel
    {
        public int TotalPatients { get; set; }
        public int PatientsToday { get; set; }
        public int PatientsYesterday { get; set; }
        public int PendingFollowUps { get; set; }
        public int VisitsThisMonth { get; set; }
        public int MonthlyTarget { get; set; }

        // Calculated property for the UI arrow (e.g. "+3 from yesterday")
        public int DailyDifference => PatientsToday - PatientsYesterday;
    }
}
