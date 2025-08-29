using Microsoft.AspNetCore.Mvc.RazorPages;
using Npgsql;
using Dairy.Infrastructure;

public class BasePageModel : PageModel
{
    protected NpgsqlConnection GetConnection()
    {
        var connectionFactory = HttpContext.RequestServices.GetRequiredService<SqlConnectionFactory>();
        return (NpgsqlConnection)connectionFactory.CreateConnection();
    }
}