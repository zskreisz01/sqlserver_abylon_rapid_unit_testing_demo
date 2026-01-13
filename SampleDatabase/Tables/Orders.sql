CREATE TABLE [dbo].[Orders]
(
    [OrderId] INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    [CustomerId] INT NOT NULL,
    [OrderDate] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [TotalAmount] DECIMAL(18,2) NOT NULL,
    [Status] NVARCHAR(20) NOT NULL DEFAULT 'Pending',
    [ShippingAddress] NVARCHAR(200) NULL,
    [CreatedDate] DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT [FK_Orders_Customers] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customers]([CustomerId])
)
GO

CREATE INDEX [IX_Orders_CustomerId] ON [dbo].[Orders] ([CustomerId])
GO

CREATE INDEX [IX_Orders_OrderDate] ON [dbo].[Orders] ([OrderDate])
GO
