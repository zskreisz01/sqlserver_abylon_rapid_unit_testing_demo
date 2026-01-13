CREATE TABLE [dbo].[Customers]
(
    [CustomerId] INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    [FirstName] NVARCHAR(50) NOT NULL,
    [LastName] NVARCHAR(50) NOT NULL,
    [Email] NVARCHAR(100) NOT NULL,
    [PhoneNumber] NVARCHAR(20) NULL,
    [CreatedDate] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [ModifiedDate] DATETIME2 NOT NULL DEFAULT GETDATE()
)
GO

CREATE INDEX [IX_Customers_Email] ON [dbo].[Customers] ([Email])
GO
