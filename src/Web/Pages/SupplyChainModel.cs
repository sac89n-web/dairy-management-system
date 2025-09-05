using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace Dairy.Web.Pages;

public class SupplyChainModel : PageModel
{
    public List<SupplyChainInventoryItem> InventoryItems { get; set; } = new();
    public List<InventoryMaster> InventoryMaster { get; set; } = new();
    public List<Shipment> Shipments { get; set; } = new();
    public List<Supplier> Suppliers { get; set; } = new();

    public async Task<IActionResult> OnPostAddInventoryAsync()
    {
        try
        {
            var masterItemId = int.Parse(Request.Form["masterItemId"]);
            var currentStock = decimal.Parse(Request.Form["currentStock"]);
            var reorderLevel = decimal.Parse(Request.Form["reorderLevel"]);
            var unitPrice = decimal.Parse(Request.Form["unitPrice"]);
            
            // In a real application, save to database
            // For now, just return success
            
            TempData["SuccessMessage"] = "Inventory item added successfully!";
            return RedirectToPage();
        }
        catch (Exception ex)
        {
            TempData["ErrorMessage"] = $"Error adding inventory item: {ex.Message}";
            return RedirectToPage();
        }
    }
    
    public async Task<IActionResult> OnPostAddSupplierAsync()
    {
        try
        {
            var supplierName = Request.Form["supplierName"];
            var supplierCode = Request.Form["supplierCode"];
            var contactPerson = Request.Form["contactPerson"];
            var phone = Request.Form["phone"];
            
            // In a real application, save to database
            // For now, just return success
            
            TempData["SuccessMessage"] = "Supplier added successfully!";
            return RedirectToPage();
        }
        catch (Exception ex)
        {
            TempData["ErrorMessage"] = $"Error adding supplier: {ex.Message}";
            return RedirectToPage();
        }
    }

    public async Task OnGetAsync()
    {
        // Load inventory master data
        InventoryMaster = new List<InventoryMaster>
        {
            new() { Id = 1, ItemName = "Cattle Feed Premium", ItemCode = "CF001", Category = "Feed", Unit = "Kg", StandardPrice = 45.50m },
            new() { Id = 2, ItemName = "Cattle Feed Standard", ItemCode = "CF002", Category = "Feed", Unit = "Kg", StandardPrice = 35.00m },
            new() { Id = 3, ItemName = "Milk Bottles 1L", ItemCode = "MB001", Category = "Packaging", Unit = "Pcs", StandardPrice = 12.00m },
            new() { Id = 4, ItemName = "Milk Bottles 500ml", ItemCode = "MB002", Category = "Packaging", Unit = "Pcs", StandardPrice = 8.00m },
            new() { Id = 5, ItemName = "Veterinary Medicine A", ItemCode = "VM001", Category = "Medicine", Unit = "Box", StandardPrice = 150.00m },
            new() { Id = 6, ItemName = "Veterinary Medicine B", ItemCode = "VM002", Category = "Medicine", Unit = "Box", StandardPrice = 200.00m },
            new() { Id = 7, ItemName = "Milking Equipment Set", ItemCode = "ME001", Category = "Equipment", Unit = "Pcs", StandardPrice = 2500.00m },
            new() { Id = 8, ItemName = "Milking Buckets", ItemCode = "ME002", Category = "Equipment", Unit = "Pcs", StandardPrice = 150.00m },
            new() { Id = 9, ItemName = "Organic Feed Premium", ItemCode = "OF001", Category = "Feed", Unit = "Kg", StandardPrice = 55.00m },
            new() { Id = 10, ItemName = "Feed Supplements", ItemCode = "FS001", Category = "Feed", Unit = "Kg", StandardPrice = 75.00m }
        };

        // Sample current inventory data
        InventoryItems = new List<SupplyChainInventoryItem>
        {
            new() { Id = 1, MasterItemId = 1, ItemName = "Cattle Feed Premium", ItemCode = "CF001", Category = "Feed", CurrentStock = 500, ReorderLevel = 100, Unit = "Kg", UnitPrice = 45.50m },
            new() { Id = 2, MasterItemId = 3, ItemName = "Milk Bottles 1L", ItemCode = "MB001", Category = "Packaging", CurrentStock = 50, ReorderLevel = 200, Unit = "Pcs", UnitPrice = 12.00m },
            new() { Id = 3, MasterItemId = 5, ItemName = "Veterinary Medicine A", ItemCode = "VM001", Category = "Medicine", CurrentStock = 25, ReorderLevel = 50, Unit = "Box", UnitPrice = 150.00m },
            new() { Id = 4, MasterItemId = 7, ItemName = "Milking Equipment Set", ItemCode = "ME001", Category = "Equipment", CurrentStock = 5, ReorderLevel = 3, Unit = "Pcs", UnitPrice = 2500.00m },
            new() { Id = 5, MasterItemId = 9, ItemName = "Organic Feed Premium", ItemCode = "OF001", Category = "Feed", CurrentStock = 300, ReorderLevel = 150, Unit = "Kg", UnitPrice = 55.00m }
        };

        Shipments = new List<Shipment>
        {
            new() { Id = 1, ShipmentNumber = "SH001", FromLocation = "Main Warehouse", ToLocation = "Branch A", ItemCount = 5, Status = "In Transit", ShippedDate = DateTime.Today.AddDays(-2), ExpectedDelivery = DateTime.Today.AddDays(1) },
            new() { Id = 2, ShipmentNumber = "SH002", FromLocation = "Supplier XYZ", ToLocation = "Main Warehouse", ItemCount = 3, Status = "Delivered", ShippedDate = DateTime.Today.AddDays(-5), ExpectedDelivery = DateTime.Today.AddDays(-3) },
            new() { Id = 3, ShipmentNumber = "SH003", FromLocation = "Branch B", ToLocation = "Branch C", ItemCount = 2, Status = "Pending", ShippedDate = DateTime.Today, ExpectedDelivery = DateTime.Today.AddDays(3) }
        };

        Suppliers = new List<Supplier>
        {
            new() { Id = 1, SupplierName = "AgriCorp Ltd", SupplierCode = "SUP001", ContactPerson = "John Smith", Phone = "9876543210", Email = "john@agricorp.com", Category = "Feed Supplier", Rating = 4.5m, IsActive = true, LastOrderDate = DateTime.Today.AddDays(-10), TotalOrders = 25 },
            new() { Id = 2, SupplierName = "VetMed Solutions", SupplierCode = "SUP002", ContactPerson = "Dr. Sarah Wilson", Phone = "9876543211", Email = "sarah@vetmed.com", Category = "Medicine Supplier", Rating = 4.8m, IsActive = true, LastOrderDate = DateTime.Today.AddDays(-5), TotalOrders = 15 },
            new() { Id = 3, SupplierName = "PackPro Industries", SupplierCode = "SUP003", ContactPerson = "Mike Johnson", Phone = "9876543212", Email = "mike@packpro.com", Category = "Packaging Supplier", Rating = 4.2m, IsActive = true, LastOrderDate = DateTime.Today.AddDays(-15), TotalOrders = 30 },
            new() { Id = 4, SupplierName = "TechEquip Co", SupplierCode = "SUP004", ContactPerson = "Lisa Brown", Phone = "9876543213", Email = "lisa@techequip.com", Category = "Equipment Supplier", Rating = 4.6m, IsActive = false, LastOrderDate = DateTime.Today.AddDays(-60), TotalOrders = 8 }
        };
    }
}

public class InventoryMaster
{
    public int Id { get; set; }
    public string ItemName { get; set; } = "";
    public string ItemCode { get; set; } = "";
    public string Category { get; set; } = "";
    public string Unit { get; set; } = "";
    public decimal StandardPrice { get; set; }
}

public class SupplyChainInventoryItem
{
    public int Id { get; set; }
    public int MasterItemId { get; set; }
    public string ItemName { get; set; } = "";
    public string ItemCode { get; set; } = "";
    public string Category { get; set; } = "";
    public decimal CurrentStock { get; set; }
    public decimal ReorderLevel { get; set; }
    public string Unit { get; set; } = "";
    public decimal UnitPrice { get; set; }
}

public class Shipment
{
    public int Id { get; set; }
    public string ShipmentNumber { get; set; } = "";
    public string FromLocation { get; set; } = "";
    public string ToLocation { get; set; } = "";
    public int ItemCount { get; set; }
    public string Status { get; set; } = "";
    public DateTime ShippedDate { get; set; }
    public DateTime? ExpectedDelivery { get; set; }
}

public class Supplier
{
    public int Id { get; set; }
    public string SupplierName { get; set; } = "";
    public string SupplierCode { get; set; } = "";
    public string ContactPerson { get; set; } = "";
    public string Phone { get; set; } = "";
    public string Email { get; set; } = "";
    public string Address { get; set; } = "";
    public string Category { get; set; } = "";
    public decimal Rating { get; set; }
    public bool IsActive { get; set; }
    public DateTime? LastOrderDate { get; set; }
    public int TotalOrders { get; set; }
}