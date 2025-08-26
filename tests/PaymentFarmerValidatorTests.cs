using Dairy.Domain;
using Dairy.Application;
using FluentValidation;
using Microsoft.Extensions.Localization;
using Xunit;
using Moq;

public class PaymentFarmerValidatorTests
{
    private readonly IValidator<PaymentFarmer> _validator;

    public PaymentFarmerValidatorTests()
    {
        var localizerMock = new Mock<IStringLocalizer>();
        _validator = new PaymentFarmerValidator(localizerMock.Object);
    }

    [Fact]
    public void ValidPaymentFarmer_PassesValidation()
    {
        var entity = new PaymentFarmer { FarmerId = 1, MilkCollectionId = 1, Amount = 100, Date = "2025-08-18", InvoiceNo = "INV001", PdfPath = "invoice.pdf" };
        var result = _validator.Validate(entity);
        Assert.True(result.IsValid);
    }

    [Fact]
    public void InvalidAmount_FailsValidation()
    {
        var entity = new PaymentFarmer { FarmerId = 1, MilkCollectionId = 1, Amount = 0, Date = "2025-08-18", InvoiceNo = "INV001", PdfPath = "invoice.pdf" };
        var result = _validator.Validate(entity);
        Assert.False(result.IsValid);
    }
}
