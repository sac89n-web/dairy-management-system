using Dairy.Infrastructure;

namespace Dairy.Web.Middleware
{
    public class AuthorizationMiddleware
    {
        private readonly RequestDelegate _next;

        public AuthorizationMiddleware(RequestDelegate next)
        {
            _next = next;
        }

        public async Task InvokeAsync(HttpContext context, IAuthService authService)
        {
            var path = context.Request.Path.Value?.ToLower() ?? "";
            
            var publicPaths = new[] 
            { 
                "/simple-login", "/login", "/database-login", "/health", 
                "/api/test-db", "/swagger", "/list-tables", "/db-test", "/setup-db" 
            };

            if (publicPaths.Any(p => path.StartsWith(p)))
            {
                await _next(context);
                return;
            }

            var userIdStr = context.Session.GetString("UserId");
            if (string.IsNullOrEmpty(userIdStr) || !int.TryParse(userIdStr, out var userId))
            {
                context.Response.Redirect("/simple-login");
                return;
            }

            var user = await authService.GetUserByIdAsync(userId);
            if (user == null || !user.IsActive)
            {
                context.Session.Clear();
                context.Response.Redirect("/simple-login");
                return;
            }

            context.Items["User"] = user;

            var hasPermission = await CheckPermission(path, user.Id, authService);
            if (!hasPermission)
            {
                context.Response.StatusCode = 403;
                await context.Response.WriteAsync("Access Denied");
                return;
            }

            await _next(context);
        }

        private async Task<bool> CheckPermission(string path, int userId, IAuthService authService)
        {
            var permissionMap = new Dictionary<string, string>
            {
                { "/milkcollections", "milk_collection.view" },
                { "/sales", "sales.view" },
                { "/masterdata", "farmers.view" },
                { "/rateslabs", "rates.view" },
                { "/reports", "reports.view" },
                { "/dashboard", "dashboard.view" }
            };

            foreach (var (pathPattern, permission) in permissionMap)
            {
                if (path.StartsWith(pathPattern))
                {
                    return await authService.HasPermissionAsync(userId, permission);
                }
            }

            return true;
        }
    }
}