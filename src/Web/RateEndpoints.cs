using Microsoft.AspNetCore.Mvc;
using Dairy.Infrastructure;

public static class RateEndpoints
{
    public static async Task<IResult> CalculateRate(
        [FromServices] IRateEngineService rateEngine,
        [FromQuery] decimal fat,
        [FromQuery] decimal snf,
        [FromQuery] decimal quantity = 1)
    {
        var result = await rateEngine.CalculateRateAsync(fat, snf, quantity);
        
        if (!result.IsValid)
        {
            return Results.BadRequest(new { error = result.ErrorMessage });
        }
        
        return Results.Ok(new
        {
            rate = result.Rate,
            baseRate = result.BaseRate,
            incentive = result.Incentive,
            slabInfo = result.SlabInfo,
            totalAmount = result.Rate * quantity
        });
    }
    
    public static async Task<IResult> GetActiveSlabs([FromServices] IRateEngineService rateEngine)
    {
        var slabs = await rateEngine.GetActiveSlabsAsync();
        return Results.Ok(slabs);
    }
}