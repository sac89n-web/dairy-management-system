using Dairy.Domain;
using Dairy.Application;
using FluentValidation;
using Microsoft.Extensions.Localization;
using Xunit;
using Moq;

public class MilkCollectionValidatorTests
{
    private readonly IValidator<MilkCollection> _validator;

    public MilkCollectionValidatorTests()
    {
        var localizerMock = new Mock<IStringLocalizer>();
        localizerMock.Setup(l => l["Error_QuantityRange"]).Returns(new LocalizedString("Error_QuantityRange", "Quantity must be between 0 and 999."));
        localizerMock.Setup(l => l["Error_FatPctRange"]).Returns(new LocalizedString("Error_FatPctRange", "Fat % must be between 0 and 15."));
        _validator = new MilkCollectionValidator(localizerMock.Object);
    }

    [Fact]
    public void ValidMilkCollection_PassesValidation()
    {
        var entity = new MilkCollection { FarmerId = 1, ShiftId = 1, Date = "2025-08-18", QtyLtr = 10, FatPct = 7, PricePerLtr = 50, DueAmt = 0, CreatedBy = 1 };
        var result = _validator.Validate(entity);
        Assert.True(result.IsValid);
    }

    [Fact]
    public void InvalidQuantity_FailsValidation()
    {
        var entity = new MilkCollection { FarmerId = 1, ShiftId = 1, Date = "2025-08-18", QtyLtr = 1000, FatPct = 7, PricePerLtr = 50, DueAmt = 0, CreatedBy = 1 };
        var result = _validator.Validate(entity);
        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.ErrorMessage.Contains("Quantity must be between 0 and 999."));
    }

    [Fact]
    public void InvalidFatPct_FailsValidation()
    {
        var entity = new MilkCollection { FarmerId = 1, ShiftId = 1, Date = "2025-08-18", QtyLtr = 10, FatPct = 20, PricePerLtr = 50, DueAmt = 0, CreatedBy = 1 };
        var result = _validator.Validate(entity);
        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.ErrorMessage.Contains("Fat % must be between 0 and 15."));
    }
}
