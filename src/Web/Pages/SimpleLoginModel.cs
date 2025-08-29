using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Dairy.Infrastructure;

public class SimpleLoginModel : PageModel
{
    private readonly IAuthService _authService;

    public SimpleLoginModel(IAuthService authService)
    {
        _authService = authService;
    }

    public string Username { get; set; } = "";
    public string ErrorMessage { get; set; } = "";
    public string SuccessMessage { get; set; } = "";

    public async Task OnGetAsync()
    {
        // Check if database connection exists
        var connectionString = HttpContext.Session.GetString("ConnectionString");
        if (!string.IsNullOrEmpty(connectionString))
        {
            await _authService.EnsureDefaultUsersAsync();
        }
        
        if (HttpContext.Session.GetString("UserId") != null)
        {
            Response.Redirect("/Dashboard");
        }
    }

    public async Task<IActionResult> OnPostAsync(string username, string password)
    {
        Username = username;

        try
        {
            var result = await _authService.LoginAsync(username, password);
            
            if (result.Success && result.User != null)
            {
                // Check if database connection exists
                var connectionString = HttpContext.Session.GetString("ConnectionString");
                if (string.IsNullOrEmpty(connectionString))
                {
                    ErrorMessage = "Please connect to database first via Database Login.";
                    return Page();
                }
                
                HttpContext.Session.SetString("UserId", result.User.Id.ToString());
                HttpContext.Session.SetString("UserName", result.User.FullName);
                HttpContext.Session.SetString("UserRole", result.User.Role.ToString());
                HttpContext.Session.SetString("UserMobile", result.User.Mobile);
                HttpContext.Session.SetString("DatabaseConnected", "true");

                return RedirectToPage("/Dashboard");
            }
            else
            {
                ErrorMessage = result.Message;
                return Page();
            }
        }
        catch (Exception ex)
        {
            ErrorMessage = $"Login failed: {ex.Message}";
            return Page();
        }
    }
}