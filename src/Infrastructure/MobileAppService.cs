using Dapper;
using Npgsql;
using System.Text.Json;

namespace Dairy.Infrastructure;

public class MobileAppService : IMobileAppService
{
    private readonly SqlConnectionFactory _connectionFactory;
    private readonly HttpClient _httpClient;

    public MobileAppService(SqlConnectionFactory connectionFactory, HttpClient httpClient)
    {
        _connectionFactory = connectionFactory;
        _httpClient = httpClient;
    }

    public async Task<MobileAuthResult> AuthenticateAsync(string deviceId, string userType, string credentials)
    {
        using var connection = (NpgsqlConnection)_connectionFactory.CreateConnection();
        await connection.OpenAsync();

        try
        {
            // Simulate authentication logic
            var user = await connection.QuerySingleOrDefaultAsync<MobileUser>(@"
                SELECT * FROM dairy.mobile_app_users 
                WHERE device_id = @deviceId AND user_type = @userType AND is_active = true",
                new { deviceId, userType });

            if (user == null)
            {
                // Create new mobile user
                var userId = await connection.QuerySingleAsync<int>(@"
                    INSERT INTO dairy.mobile_app_users 
                    (user_type, device_id, app_version, is_active)
                    VALUES (@userType, @deviceId, '1.0.0', true)
                    RETURNING id",
                    new { userType, deviceId });

                user = new MobileUser
                {
                    Id = userId,
                    UserType = userType,
                    DeviceId = deviceId,
                    AppVersion = "1.0.0",
                    IsActive = true
                };
            }

            // Generate JWT token (simplified)
            var token = GenerateJwtToken(user);

            return new MobileAuthResult
            {
                Success = true,
                Token = token,
                User = user,
                Message = "Authentication successful"
            };
        }
        catch (Exception ex)
        {
            return new MobileAuthResult
            {
                Success = false,
                Message = $"Authentication failed: {ex.Message}"
            };
        }
    }

    public async Task<SyncResult> SyncDataAsync(int userId, SyncRequest request)
    {
        using var connection = (NpgsqlConnection)_connectionFactory.CreateConnection();
        await connection.OpenAsync();

        try
        {
            var syncResult = new SyncResult
            {
                Success = true,
                SyncTimestamp = DateTime.Now
            };

            switch (request.SyncType.ToLower())
            {
                case "collection":
                    syncResult = await SyncCollectionDataAsync(connection, userId, request);
                    break;
                case "farmer_data":
                    syncResult = await SyncFarmerDataAsync(connection, userId, request);
                    break;
                case "payment":
                    syncResult = await SyncPaymentDataAsync(connection, userId, request);
                    break;
                default:
                    syncResult.Message = "Unknown sync type";
                    break;
            }

            // Log sync activity
            await connection.ExecuteAsync(@"
                INSERT INTO dairy.mobile_sync_logs 
                (user_id, sync_type, records_synced, sync_status)
                VALUES (@userId, @syncType, @recordsSynced, @status)",
                new
                {
                    userId,
                    syncType = request.SyncType,
                    recordsSynced = syncResult.RecordsSynced,
                    status = syncResult.Success ? "success" : "failed"
                });

            // Update last sync time
            await connection.ExecuteAsync(@"
                UPDATE dairy.mobile_app_users 
                SET last_sync = @syncTime 
                WHERE id = @userId",
                new { syncTime = syncResult.SyncTimestamp, userId });

            return syncResult;
        }
        catch (Exception ex)
        {
            return new SyncResult
            {
                Success = false,
                Message = $"Sync failed: {ex.Message}"
            };
        }
    }

    public async Task<bool> SendPushNotificationAsync(int userId, PushNotification notification)
    {
        using var connection = (NpgsqlConnection)_connectionFactory.CreateConnection();
        await connection.OpenAsync();

        try
        {
            var user = await connection.QuerySingleOrDefaultAsync<MobileUser>(@"
                SELECT * FROM dairy.mobile_app_users WHERE id = @userId",
                new { userId });

            if (user?.FcmToken == null) return false;

            // Simulate FCM push notification
            var fcmPayload = new
            {
                to = user.FcmToken,
                notification = new
                {
                    title = notification.Title,
                    body = notification.Body
                },
                data = notification.Data
            };

            // In real implementation, send to FCM
            await Task.Delay(100); // Simulate API call

            return true;
        }
        catch
        {
            return false;
        }
    }

    public async Task<List<MobileUser>> GetActiveUsersAsync()
    {
        using var connection = (NpgsqlConnection)_connectionFactory.CreateConnection();
        await connection.OpenAsync();

        try
        {
            return (await connection.QueryAsync<MobileUser>(@"
                SELECT * FROM dairy.mobile_app_users 
                WHERE is_active = true 
                ORDER BY last_sync DESC")).ToList();
        }
        catch
        {
            return new List<MobileUser>();
        }
    }

    public async Task<MobileDashboard> GetMobileDashboardAsync(int userId)
    {
        using var connection = (NpgsqlConnection)_connectionFactory.CreateConnection();
        await connection.OpenAsync();

        var dashboard = new MobileDashboard();

        try
        {
            var user = await connection.QuerySingleOrDefaultAsync<MobileUser>(@"
                SELECT * FROM dairy.mobile_app_users WHERE id = @userId",
                new { userId });

            if (user == null) return dashboard;

            dashboard.UserName = user.UserType == "farmer" ? "Farmer User" : "Field Officer";
            dashboard.UserType = user.UserType;

            // Get stats based on user type
            if (user.UserType == "farmer" && user.FarmerId.HasValue)
            {
                dashboard.Stats = await GetFarmerStatsAsync(connection, user.FarmerId.Value);
            }
            else
            {
                dashboard.Stats = await GetFieldOfficerStatsAsync(connection);
            }

            // Get recent activities
            dashboard.RecentActivities = await GetRecentActivitiesAsync(connection, userId);

            // Get pending tasks
            dashboard.PendingTasks = await GetPendingTasksAsync(connection, userId);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Mobile dashboard error: {ex.Message}");
        }

        return dashboard;
    }

    private async Task<SyncResult> SyncCollectionDataAsync(NpgsqlConnection connection, int userId, SyncRequest request)
    {
        // Simulate collection data sync
        var serverData = await connection.QueryAsync(@"
            SELECT id, farmer_id, date, qty_ltr, fat_pct, due_amt
            FROM dairy.milk_collection 
            WHERE date >= @lastSync
            ORDER BY date DESC
            LIMIT 100",
            new { lastSync = request.LastSyncTime });

        return new SyncResult
        {
            Success = true,
            RecordsSynced = serverData.Count(),
            ServerData = serverData.Cast<object>().ToList(),
            SyncTimestamp = DateTime.Now,
            Message = "Collection data synced successfully"
        };
    }

    private async Task<SyncResult> SyncFarmerDataAsync(NpgsqlConnection connection, int userId, SyncRequest request)
    {
        // Simulate farmer data sync
        var serverData = await connection.QueryAsync(@"
            SELECT id, name, code, contact, branch_id
            FROM dairy.farmer 
            WHERE created_at >= @lastSync OR updated_at >= @lastSync
            ORDER BY name
            LIMIT 100",
            new { lastSync = request.LastSyncTime });

        return new SyncResult
        {
            Success = true,
            RecordsSynced = serverData.Count(),
            ServerData = serverData.Cast<object>().ToList(),
            SyncTimestamp = DateTime.Now,
            Message = "Farmer data synced successfully"
        };
    }

    private async Task<SyncResult> SyncPaymentDataAsync(NpgsqlConnection connection, int userId, SyncRequest request)
    {
        // Simulate payment data sync
        var serverData = await connection.QueryAsync(@"
            SELECT id, farmer_id, amount, date, invoice_no
            FROM dairy.payment_farmer 
            WHERE date >= @lastSync
            ORDER BY date DESC
            LIMIT 100",
            new { lastSync = request.LastSyncTime });

        return new SyncResult
        {
            Success = true,
            RecordsSynced = serverData.Count(),
            ServerData = serverData.Cast<object>().ToList(),
            SyncTimestamp = DateTime.Now,
            Message = "Payment data synced successfully"
        };
    }

    private async Task<DashboardStats> GetFarmerStatsAsync(NpgsqlConnection connection, int farmerId)
    {
        try
        {
            return await connection.QuerySingleOrDefaultAsync<DashboardStats>(@"
                SELECT 
                    COALESCE(SUM(CASE WHEN date = CURRENT_DATE THEN qty_ltr END), 0) as TodayCollection,
                    1 as TotalFarmers,
                    COALESCE(AVG(CASE WHEN date >= CURRENT_DATE - INTERVAL '7 days' THEN fat_pct END), 0) as AverageQuality,
                    COALESCE(COUNT(CASE WHEN pf.date IS NULL THEN 1 END), 0) as PendingPayments
                FROM dairy.milk_collection mc
                LEFT JOIN dairy.payment_farmer pf ON mc.id = pf.milk_collection_id
                WHERE mc.farmer_id = @farmerId",
                new { farmerId }) ?? new DashboardStats();
        }
        catch
        {
            return new DashboardStats();
        }
    }

    private async Task<DashboardStats> GetFieldOfficerStatsAsync(NpgsqlConnection connection)
    {
        try
        {
            return await connection.QuerySingleOrDefaultAsync<DashboardStats>(@"
                SELECT 
                    COALESCE(SUM(CASE WHEN date = CURRENT_DATE THEN qty_ltr END), 0) as TodayCollection,
                    COUNT(DISTINCT farmer_id) as TotalFarmers,
                    COALESCE(AVG(fat_pct), 0) as AverageQuality,
                    0 as PendingPayments
                FROM dairy.milk_collection 
                WHERE date >= CURRENT_DATE - INTERVAL '30 days'") ?? new DashboardStats();
        }
        catch
        {
            return new DashboardStats();
        }
    }

    private async Task<List<RecentActivity>> GetRecentActivitiesAsync(NpgsqlConnection connection, int userId)
    {
        // Mock recent activities
        return new List<RecentActivity>
        {
            new RecentActivity
            {
                ActivityType = "collection",
                Description = "Milk collection recorded - 25.5L",
                Timestamp = DateTime.Now.AddMinutes(-30),
                Status = "completed"
            },
            new RecentActivity
            {
                ActivityType = "payment",
                Description = "Payment processed - ₹1,250",
                Timestamp = DateTime.Now.AddHours(-2),
                Status = "completed"
            }
        };
    }

    private async Task<List<PendingTask>> GetPendingTasksAsync(NpgsqlConnection connection, int userId)
    {
        // Mock pending tasks
        return new List<PendingTask>
        {
            new PendingTask
            {
                Id = 1,
                TaskType = "quality_check",
                Description = "Quality check for Farmer #123",
                Priority = "high",
                DueDate = DateTime.Today.AddDays(1)
            },
            new PendingTask
            {
                Id = 2,
                TaskType = "payment_approval",
                Description = "Approve payment batch #456",
                Priority = "medium",
                DueDate = DateTime.Today.AddDays(2)
            }
        };
    }

    private string GenerateJwtToken(MobileUser user)
    {
        // Simplified JWT token generation
        var payload = Convert.ToBase64String(JsonSerializer.SerializeToUtf8Bytes(new
        {
            userId = user.Id,
            userType = user.UserType,
            deviceId = user.DeviceId,
            exp = DateTimeOffset.UtcNow.AddDays(30).ToUnixTimeSeconds()
        }));

        return $"mobile.{payload}.signature";
    }
}