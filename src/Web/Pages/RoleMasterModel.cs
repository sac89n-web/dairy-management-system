using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

public class RoleMasterModel : PageModel
{
    public void OnGet()
    {
    }

    public IActionResult OnPost()
    {
        // Add role logic
        return RedirectToPage();
    }
}