CREATE VIEW [dbo].[vw_CustomerOrderSummary]
AS
SELECT
    c.[CustomerId],
    c.[FirstName],
    c.[LastName],
    c.[Email],
    COUNT(o.[OrderId]) AS TotalOrders,
    ISNULL(SUM(o.[TotalAmount]), 0) AS TotalSpent,
    MAX(o.[OrderDate]) AS LastOrderDate
FROM [dbo].[Customers] c
LEFT JOIN [dbo].[Orders] o ON c.[CustomerId] = o.[CustomerId]
GROUP BY c.[CustomerId], c.[FirstName], c.[LastName], c.[Email]
GO
