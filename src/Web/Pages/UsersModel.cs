using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Dairy.Infrastructure;
using Dairy.Domain;
using Dapper;

public class UsersModel : BasePageModel
{
    private readonly IAuthService _authService;

    public UsersModel(IAuthService authService)
    {
        _authService = authService;
    }

    public List<User> Users { get; set; } = new();

    public async Task OnGetAsync()
    {
        using var connection = GetConnection();
        
        Users = (await connection.QueryAsync<User>("SELECT * FROM dairy.users ORDER BY created_at DESC")).ToList();
    }

    public async Task<IActionResult> OnPostAddUserAsync(string username, string fullName, string email, string mobile, int role, string password)
    {
        using var connection = GetConnection();
        
        try
        {
            var passwordHash = HashPassword(password);
            
            await connection.ExecuteAsync(@"
                INSERT INTO dairy.users (username, email, password_hash, full_name, mobile, role, created_by)
                VALUES (@username, @email, @passwordHash, @fullName, @mobile, @role, @createdBy)",
                new { username, email, passwordHash, fullName, mobile, role, createdBy = GetCurrentUserId() });

            TempData["SuccessMessage"] = "User created successfully";
        }
        catch (Exception ex)
        {
            TempData["ErrorMessage"] = $"Error creating user: {ex.Message}";
        }

        return RedirectToPage();
    }

    public async Task<IActionResult> OnPostToggleUserAsync(int userId)
    {
        using var connection = GetConnection();
        
        await connection.ExecuteAsync(@"
            UPDATE dairy.users 
            SET is_active = NOT is_active 
            WHERE id = @userId AND id != 1", 
            new { userId });

        TempData["SuccessMessage"] = "User status updated successfully";
        return RedirectToPage();
    }

    private string HashPassword(string password)
    {
        using var sha256 = System.Security.Cryptography.SHA256.Create();
        var hashedBytes = sha256.ComputeHash(System.Text.Encoding.UTF8.GetBytes(password + "dairy_salt"));
        return Convert.ToBase64String(hashedBytes);
    }

    private int GetCurrentUserId()
    {
        var userIdStr = HttpContext.Session.GetString("UserId");
        return int.TryParse(userIdStr, out var userId) ? userId : 1;
    }
}