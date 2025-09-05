namespace Dairy.Infrastructure;

public interface IMobileAppService
{
    Task<MobileAuthResult> AuthenticateAsync(string deviceId, string userType, string credentials);
    Task<SyncResult> SyncDataAsync(int userId, SyncRequest request);
    Task<bool> SendPushNotificationAsync(int userId, PushNotification notification);
    Task<List<MobileUser>> GetActiveUsersAsync();
    Task<MobileDashboard> GetMobileDashboardAsync(int userId);
}

public class MobileAuthResult
{
    public bool Success { get; set; }
    public string Token { get; set; } = "";
    public MobileUser User { get; set; } = new();
    public string Message { get; set; } = "";
}

public class MobileUser
{
    public int Id { get; set; }
    public string UserType { get; set; } = "";
    public int? FarmerId { get; set; }
    public int? EmployeeId { get; set; }
    public string DeviceId { get; set; } = "";
    public string AppVersion { get; set; } = "";
    public string FcmToken { get; set; } = "";
    public DateTime? LastSync { get; set; }
    public bool IsActive { get; set; }
}

public class SyncRequest
{
    public string SyncType { get; set; } = "";
    public DateTime LastSyncTime { get; set; }
    public List<object> LocalData { get; set; } = new();
}

public class SyncResult
{
    public bool Success { get; set; }
    public int RecordsSynced { get; set; }
    public List<object> ServerData { get; set; } = new();
    public DateTime SyncTimestamp { get; set; }
    public string Message { get; set; } = "";
}

public class PushNotification
{
    public string Title { get; set; } = "";
    public string Body { get; set; } = "";
    public Dictionary<string, string> Data { get; set; } = new();
    public string NotificationType { get; set; } = "";
}

public class MobileDashboard
{
    public string UserName { get; set; } = "";
    public string UserType { get; set; } = "";
    public DashboardStats Stats { get; set; } = new();
    public List<RecentActivity> RecentActivities { get; set; } = new();
    public List<PendingTask> PendingTasks { get; set; } = new();
}

public class DashboardStats
{
    public decimal TodayCollection { get; set; }
    public int TotalFarmers { get; set; }
    public decimal AverageQuality { get; set; }
    public int PendingPayments { get; set; }
}

public class RecentActivity
{
    public string ActivityType { get; set; } = "";
    public string Description { get; set; } = "";
    public DateTime Timestamp { get; set; }
    public string Status { get; set; } = "";
}

public class PendingTask
{
    public int Id { get; set; }
    public string TaskType { get; set; } = "";
    public string Description { get; set; } = "";
    public string Priority { get; set; } = "";
    public DateTime DueDate { get; set; }
}