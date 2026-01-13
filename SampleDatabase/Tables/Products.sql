CREATE TABLE [dbo].[Products]
(
    [ProductId] INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    [ProductName] NVARCHAR(100) NOT NULL,
    [Description] NVARCHAR(500) NULL,
    [Price] DECIMAL(18,2) NOT NULL,
    [StockQuantity] INT NOT NULL DEFAULT 0,
    [IsActive] BIT NOT NULL DEFAULT 1,
    [CreatedDate] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [ModifiedDate] DATETIME2 NOT NULL DEFAULT GETDATE()
)
GO

CREATE INDEX [IX_Products_ProductName] ON [dbo].[Products] ([ProductName])
GO
