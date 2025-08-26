using Dairy.Domain;
using Dairy.Application;
using FluentValidation;
using Microsoft.Extensions.Localization;
using Xunit;
using Moq;

public class SaleValidatorTests
{
    private readonly IValidator<Sale> _validator;

    public SaleValidatorTests()
    {
        var localizerMock = new Mock<IStringLocalizer>();
        localizerMock.Setup(l => l["Error_QuantityRange"]).Returns(new LocalizedString("Error_QuantityRange", "Quantity must be between 0 and 999."));
        localizerMock.Setup(l => l["Error_PaidExceedsDue"]).Returns(new LocalizedString("Error_PaidExceedsDue", "Paid amount cannot exceed due amount."));
        _validator = new SaleValidator(localizerMock.Object);
    }

    [Fact]
    public void ValidSale_PassesValidation()
    {
        var entity = new Sale { CustomerId = 1, ShiftId = 1, Date = "2025-08-18", QtyLtr = 10, UnitPrice = 50, Discount = 0, PaidAmt = 10, DueAmt = 10, CreatedBy = 1 };
        var result = _validator.Validate(entity);
        Assert.True(result.IsValid);
    }

    [Fact]
    public void InvalidQuantity_FailsValidation()
    {
        var entity = new Sale { CustomerId = 1, ShiftId = 1, Date = "2025-08-18", QtyLtr = 1000, UnitPrice = 50, Discount = 0, PaidAmt = 10, DueAmt = 10, CreatedBy = 1 };
        var result = _validator.Validate(entity);
        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.ErrorMessage.Contains("Quantity must be between 0 and 999."));
    }

    [Fact]
    public void PaidExceedsDue_FailsValidation()
    {
        var entity = new Sale { CustomerId = 1, ShiftId = 1, Date = "2025-08-18", QtyLtr = 10, UnitPrice = 50, Discount = 0, PaidAmt = 20, DueAmt = 10, CreatedBy = 1 };
        var result = _validator.Validate(entity);
        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.ErrorMessage.Contains("Paid amount cannot exceed due amount."));
    }
}
