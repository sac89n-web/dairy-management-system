using Microsoft.AspNetCore.Mvc;
using Dairy.Infrastructure;
using Dairy.Reports;

namespace Dairy.Web;

public static class FeedbackFeaturesEndpoints
{
    public static void MapFeedbackFeatures(this WebApplication app)
    {
        var group = app.MapGroup("/api/feedback-features").WithTags("Feedback Implementation");

        // Payment Cycles Endpoints
        group.MapPost("/payment-cycles", CreatePaymentCycle);
        group.MapPost("/payment-cycles/{cycleId}/process", ProcessPaymentCycle);
        group.MapPost("/payment-cycles/{cycleId}/bank-file", GenerateBankFile);
        group.MapGet("/payment-cycles/{cycleId}/details", GetCycleDetails);

        // Bonus Management Endpoints
        group.MapPost("/bonus/calculate-half-yearly", CalculateHalfYearlyBonus);
        group.MapPost("/bonus/calculate-yearly", CalculateYearlyBonus);
        group.MapPost("/bonus/{bonusId}/approve", ApproveBonus);
        group.MapPost("/bonus/{bonusId}/pay/{cycleId}", ProcessBonusPayment);
        group.MapGet("/bonus/configurations", GetBonusConfigurations);

        // Notification Endpoints
        group.MapPost("/notifications/collection-receipt", SendCollectionReceipt);
        group.MapPost("/notifications/payment-notification", SendPaymentNotification);
        group.MapPost("/notifications/bonus-notification", SendBonusNotification);
        group.MapPost("/notifications/quality-alert", SendQualityAlert);
        group.MapGet("/notifications/alerts", GetUnresolvedAlerts);

        // Analytics & Reports Endpoints
        group.MapGet("/analytics/dashboard-kpis", GetDashboardKpis);
        group.MapGet("/analytics/farmer-performance", GetFarmerPerformanceReport);
        group.MapGet("/analytics/quality-trend", GetQualityTrendReport);
        group.MapGet("/analytics/payment-summary", GetPaymentSummaryReport);
        group.MapGet("/analytics/export/{reportType}", ExportReport);
        group.MapPost("/analytics/schedule-report", ScheduleReport);
    }

    // Payment Cycle Endpoints
    private static async Task<IResult> CreatePaymentCycle(
        [FromBody] CreatePaymentCycleRequest request,
        IPaymentCycleService paymentCycleService)
    {
        try
        {
            var cycleId = await paymentCycleService.CreatePaymentCycleAsync(request.StartDate, request.EndDate);
            return Results.Ok(new { success = true, cycleId, message = "Payment cycle created successfully" });
        }
        catch (Exception ex)
        {
            return Results.BadRequest(new { success = false, error = ex.Message });
        }
    }

    private static async Task<IResult> ProcessPaymentCycle(
        int cycleId,
        IPaymentCycleService paymentCycleService)
    {
        try
        {
            var success = await paymentCycleService.ProcessPaymentCycleAsync(cycleId);
            return Results.Ok(new { success, message = success ? "Payment cycle processed successfully" : "Failed to process payment cycle" });
        }
        catch (Exception ex)
        {
            return Results.BadRequest(new { success = false, error = ex.Message });
        }
    }

    private static async Task<IResult> GenerateBankFile(
        int cycleId,
        [FromQuery] string bankName,
        IPaymentCycleService paymentCycleService)
    {
        try
        {
            var filePath = await paymentCycleService.GenerateBankFileAsync(cycleId, bankName);
            return Results.Ok(new { success = true, filePath, message = "Bank file generated successfully" });
        }
        catch (Exception ex)
        {
            return Results.BadRequest(new { success = false, error = ex.Message });
        }
    }

    private static async Task<IResult> GetCycleDetails(
        int cycleId,
        IPaymentCycleService paymentCycleService)
    {
        try
        {
            var details = await paymentCycleService.GetCycleDetailsAsync(cycleId);
            return Results.Ok(new { success = true, data = details });
        }
        catch (Exception ex)
        {
            return Results.BadRequest(new { success = false, error = ex.Message });
        }
    }

    // Bonus Management Endpoints
    private static async Task<IResult> CalculateHalfYearlyBonus(
        [FromBody] CalculateBonusRequest request,
        IBonusService bonusService)
    {
        try
        {
            var calculations = await bonusService.CalculateHalfYearlyBonusAsync(request.PeriodStart, request.PeriodEnd);
            return Results.Ok(new { success = true, data = calculations, count = calculations.Count });
        }
        catch (Exception ex)
        {
            return Results.BadRequest(new { success = false, error = ex.Message });
        }
    }

    private static async Task<IResult> CalculateYearlyBonus(
        [FromBody] CalculateBonusRequest request,
        IBonusService bonusService)
    {
        try
        {
            var calculations = await bonusService.CalculateYearlyBonusAsync(request.PeriodStart, request.PeriodEnd);
            return Results.Ok(new { success = true, data = calculations, count = calculations.Count });
        }
        catch (Exception ex)
        {
            return Results.BadRequest(new { success = false, error = ex.Message });
        }
    }

    private static async Task<IResult> ApproveBonus(
        int bonusId,
        [FromBody] ApproveBonusRequest request,
        IBonusService bonusService)
    {
        try
        {
            var success = await bonusService.ApproveBonusAsync(bonusId, request.ApprovedBy);
            return Results.Ok(new { success, message = success ? "Bonus approved successfully" : "Failed to approve bonus" });
        }
        catch (Exception ex)
        {
            return Results.BadRequest(new { success = false, error = ex.Message });
        }
    }

    private static async Task<IResult> ProcessBonusPayment(
        int bonusId,
        int cycleId,
        IBonusService bonusService)
    {
        try
        {
            var success = await bonusService.ProcessBonusPaymentAsync(bonusId, cycleId);
            return Results.Ok(new { success, message = success ? "Bonus payment processed successfully" : "Failed to process bonus payment" });
        }
        catch (Exception ex)
        {
            return Results.BadRequest(new { success = false, error = ex.Message });
        }
    }

    private static async Task<IResult> GetBonusConfigurations(IBonusService bonusService)
    {
        try
        {
            var configurations = await bonusService.GetActiveBonusConfigurationsAsync();
            return Results.Ok(new { success = true, data = configurations });
        }
        catch (Exception ex)
        {
            return Results.BadRequest(new { success = false, error = ex.Message });
        }
    }

    // Notification Endpoints
    private static async Task<IResult> SendCollectionReceipt(
        [FromBody] SendCollectionReceiptRequest request,
        IAdvancedNotificationService notificationService)
    {
        try
        {
            var success = await notificationService.SendCollectionReceiptAsync(request.FarmerId, request.CollectionId);
            return Results.Ok(new { success, message = success ? "Receipt sent successfully" : "Failed to send receipt" });
        }
        catch (Exception ex)
        {
            return Results.BadRequest(new { success = false, error = ex.Message });
        }
    }

    private static async Task<IResult> SendPaymentNotification(
        [FromBody] SendPaymentNotificationRequest request,
        IAdvancedNotificationService notificationService)
    {
        try
        {
            var success = await notificationService.SendPaymentNotificationAsync(request.FarmerId, request.CycleId);
            return Results.Ok(new { success, message = success ? "Payment notification sent successfully" : "Failed to send notification" });
        }
        catch (Exception ex)
        {
            return Results.BadRequest(new { success = false, error = ex.Message });
        }
    }

    private static async Task<IResult> SendBonusNotification(
        [FromBody] SendBonusNotificationRequest request,
        IAdvancedNotificationService notificationService)
    {
        try
        {
            var success = await notificationService.SendBonusNotificationAsync(request.FarmerId, request.BonusId);
            return Results.Ok(new { success, message = success ? "Bonus notification sent successfully" : "Failed to send notification" });
        }
        catch (Exception ex)
        {
            return Results.BadRequest(new { success = false, error = ex.Message });
        }
    }

    private static async Task<IResult> SendQualityAlert(
        [FromBody] SendQualityAlertRequest request,
        IAdvancedNotificationService notificationService)
    {
        try
        {
            var success = await notificationService.SendQualityAlertAsync(request.FarmerId, request.AvgFat, request.AvgSnf);
            return Results.Ok(new { success, message = success ? "Quality alert sent successfully" : "Failed to send alert" });
        }
        catch (Exception ex)
        {
            return Results.BadRequest(new { success = false, error = ex.Message });
        }
    }

    private static async Task<IResult> GetUnresolvedAlerts(IAdvancedNotificationService notificationService)
    {
        try
        {
            var alerts = await notificationService.GetUnresolvedAlertsAsync();
            return Results.Ok(new { success = true, data = alerts, count = alerts.Count });
        }
        catch (Exception ex)
        {
            return Results.BadRequest(new { success = false, error = ex.Message });
        }
    }

    // Analytics Endpoints
    private static async Task<IResult> GetDashboardKpis(
        [FromQuery] DateTime? fromDate,
        [FromQuery] DateTime? toDate,
        IAdvancedAnalyticsService analyticsService)
    {
        try
        {
            var kpis = await analyticsService.GetDashboardKpisAsync(fromDate, toDate);
            return Results.Ok(new { success = true, data = kpis });
        }
        catch (Exception ex)
        {
            return Results.BadRequest(new { success = false, error = ex.Message });
        }
    }

    private static async Task<IResult> GetFarmerPerformanceReport(
        [FromQuery] DateTime fromDate,
        [FromQuery] DateTime toDate,
        IAdvancedAnalyticsService analyticsService)
    {
        try
        {
            var report = await analyticsService.GetFarmerPerformanceReportAsync(fromDate, toDate);
            return Results.Ok(new { success = true, data = report, count = report.Count });
        }
        catch (Exception ex)
        {
            return Results.BadRequest(new { success = false, error = ex.Message });
        }
    }

    private static async Task<IResult> GetQualityTrendReport(
        [FromQuery] DateTime fromDate,
        [FromQuery] DateTime toDate,
        IAdvancedAnalyticsService analyticsService)
    {
        try
        {
            var report = await analyticsService.GetQualityTrendReportAsync(fromDate, toDate);
            return Results.Ok(new { success = true, data = report, count = report.Count });
        }
        catch (Exception ex)
        {
            return Results.BadRequest(new { success = false, error = ex.Message });
        }
    }

    private static async Task<IResult> GetPaymentSummaryReport(
        [FromQuery] DateTime fromDate,
        [FromQuery] DateTime toDate,
        IAdvancedAnalyticsService analyticsService)
    {
        try
        {
            var report = await analyticsService.GetPaymentSummaryReportAsync(fromDate, toDate);
            return Results.Ok(new { success = true, data = report, count = report.Count });
        }
        catch (Exception ex)
        {
            return Results.BadRequest(new { success = false, error = ex.Message });
        }
    }

    private static async Task<IResult> ExportReport(
        string reportType,
        [FromQuery] DateTime fromDate,
        [FromQuery] DateTime toDate,
        IAdvancedAnalyticsService analyticsService)
    {
        try
        {
            var excelData = await analyticsService.ExportReportToExcelAsync(reportType, fromDate, toDate);
            var fileName = $"{reportType}_report_{fromDate:yyyyMMdd}_{toDate:yyyyMMdd}.xlsx";
            
            return Results.File(excelData, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", fileName);
        }
        catch (Exception ex)
        {
            return Results.BadRequest(new { success = false, error = ex.Message });
        }
    }

    private static async Task<IResult> ScheduleReport(
        [FromBody] ScheduleReportRequest request,
        IAdvancedAnalyticsService analyticsService)
    {
        try
        {
            var success = await analyticsService.ScheduleReportAsync(request.ReportName, request.ReportType, request.Schedule, request.Recipients);
            return Results.Ok(new { success, message = success ? "Report scheduled successfully" : "Failed to schedule report" });
        }
        catch (Exception ex)
        {
            return Results.BadRequest(new { success = false, error = ex.Message });
        }
    }
}

// Request DTOs
public record CreatePaymentCycleRequest(DateTime StartDate, DateTime EndDate);
public record CalculateBonusRequest(DateTime PeriodStart, DateTime PeriodEnd);
public record ApproveBonusRequest(int ApprovedBy);
public record SendCollectionReceiptRequest(int FarmerId, int CollectionId);
public record SendPaymentNotificationRequest(int FarmerId, int CycleId);
public record SendBonusNotificationRequest(int FarmerId, int BonusId);
public record SendQualityAlertRequest(int FarmerId, decimal AvgFat, decimal AvgSnf);
public record ScheduleReportRequest(string ReportName, string ReportType, string Schedule, List<string> Recipients);