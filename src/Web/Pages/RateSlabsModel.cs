using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Dairy.Infrastructure;
using Dairy.Domain;
using Dapper;

public class RateSlabsModel : BasePageModel
{
    private readonly IRateEngineService _rateEngine;

    public RateSlabsModel(IRateEngineService rateEngine)
    {
        _rateEngine = rateEngine;
    }

    public List<Dairy.Domain.RateSlab> RateSlabs { get; set; } = new();

    public async Task OnGetAsync()
    {
        await _rateEngine.EnsureDefaultSlabsAsync();
        RateSlabs = (await _rateEngine.GetActiveSlabsAsync()).ToList();
    }

    public async Task<IActionResult> OnPostAddSlabAsync(decimal fatMin, decimal fatMax, decimal snfMin, decimal snfMax, decimal baseRate, decimal incentive, DateTime effectiveFrom)
    {
        using var connection = GetConnection();
        
        await connection.ExecuteAsync(@"
            INSERT INTO dairy.rate_slabs (fat_min, fat_max, snf_min, snf_max, base_rate, incentive, effective_from)
            VALUES (@fatMin, @fatMax, @snfMin, @snfMax, @baseRate, @incentive, @effectiveFrom)",
            new { fatMin, fatMax, snfMin, snfMax, baseRate, incentive, effectiveFrom });

        TempData["SuccessMessage"] = "Rate slab added successfully";
        return RedirectToPage();
    }

    public async Task<IActionResult> OnPostDeleteSlabAsync(int id)
    {
        using var connection = GetConnection();
        
        await connection.ExecuteAsync("UPDATE dairy.rate_slabs SET is_active = false WHERE id = @id", new { id });
        
        TempData["SuccessMessage"] = "Rate slab deactivated successfully";
        return RedirectToPage();
    }
}