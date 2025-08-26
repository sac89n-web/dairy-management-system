using Dairy.Domain;
using Dairy.Application;
using FluentValidation;
using Microsoft.Extensions.Localization;
using Xunit;
using Moq;

public class PaymentCustomerValidatorTests
{
    private readonly IValidator<PaymentCustomer> _validator;

    public PaymentCustomerValidatorTests()
    {
        var localizerMock = new Mock<IStringLocalizer>();
        _validator = new PaymentCustomerValidator(localizerMock.Object);
    }

    [Fact]
    public void ValidPaymentCustomer_PassesValidation()
    {
        var entity = new PaymentCustomer { CustomerId = 1, SaleId = 1, Amount = 100, Date = "2025-08-18", InvoiceNo = "INV001", PdfPath = "invoice.pdf" };
        var result = _validator.Validate(entity);
        Assert.True(result.IsValid);
    }

    [Fact]
    public void InvalidAmount_FailsValidation()
    {
        var entity = new PaymentCustomer { CustomerId = 1, SaleId = 1, Amount = 0, Date = "2025-08-18", InvoiceNo = "INV001", PdfPath = "invoice.pdf" };
        var result = _validator.Validate(entity);
        Assert.False(result.IsValid);
    }
}
