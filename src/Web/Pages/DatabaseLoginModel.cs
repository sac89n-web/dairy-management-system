using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Npgsql;

public class DatabaseLoginModel : PageModel
{
    public DatabaseLoginModel()
    {
    }

    public string Host { get; set; } = "localhost";
    public string Database { get; set; } = "postgres";
    public string Username { get; set; } = "postgres";
    public bool RememberCredentials { get; set; } = true;
    public string ErrorMessage { get; set; } = "";

    public void OnGet()
    {
        // Check if already connected
        if (HttpContext.Session.GetString("DatabaseConnected") == "true")
        {
            Response.Redirect("/Dashboard");
        }
    }

    public async Task<IActionResult> OnPostAsync(string host, string database, string username, string password, bool rememberCredentials = false)
    {
        try
        {
            var connectionString = $"Host={host};Database={database};Username={username};Password={password};SearchPath=dairy";
            
            // Test connection
            using var connection = new NpgsqlConnection(connectionString);
            await connection.OpenAsync();
            
            // Store connection info in session
            HttpContext.Session.SetString("DatabaseConnected", "true");
            HttpContext.Session.SetString("ConnectionString", connectionString);
            
            return RedirectToPage("/simple-login");
        }
        catch (Exception ex)
        {
            Host = host;
            Database = database;
            Username = username;
            RememberCredentials = rememberCredentials;
            ErrorMessage = $"Connection failed: {ex.Message}";
            return Page();
        }
    }

    public async Task<IActionResult> OnPostTestConnectionAsync(string host, string database, string username, string password)
    {
        try
        {
            var connectionString = $"Host={host};Database={database};Username={username};Password={password};SearchPath=dairy";
            using var connection = new NpgsqlConnection(connectionString);
            await connection.OpenAsync();
            
            return new JsonResult(new { Success = true, Message = "Connection successful" });
        }
        catch (Exception ex)
        {
            return new JsonResult(new { Success = false, Error = ex.Message });
        }
    }
}