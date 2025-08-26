using Dairy.Reports;
using Xunit;
using System.Collections.Generic;

public class ReportsExportTests
{
    [Fact]
    public void ExcelReportService_GeneratesFile()
    {
        var service = new ExcelReportService();
        var rows = new List<ExcelReportService.ReportRow>
        {
            new ExcelReportService.ReportRow { Type = "Milk Collection", Date = "2025-08-18", BranchId = 1, ShiftId = 1, Amount = 100 }
        };
        var file = service.GenerateReport(rows);
        Assert.NotNull(file);
        Assert.True(file.Length > 0);
    }

    [Fact]
    public void PdfReportService_GeneratesFile()
    {
        var service = new PdfReportService();
        var rows = new List<PdfReportService.ReportRow>
        {
            new PdfReportService.ReportRow { Type = "Milk Collection", Date = "2025-08-18", BranchId = 1, ShiftId = 1, Amount = 100 }
        };
        var file = service.GenerateReport(rows, "Dairy Management System", "9876543210", "123 Dairy Lane");
        Assert.NotNull(file);
        Assert.True(file.Length > 0);
    }
}
