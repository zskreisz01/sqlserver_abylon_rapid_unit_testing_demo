CREATE PROCEDURE [dbo].[usp_GetCustomerOrders]
    @CustomerId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        o.[OrderId],
        o.[OrderDate],
        o.[TotalAmount],
        o.[Status],
        o.[ShippingAddress],
        c.[FirstName],
        c.[LastName],
        c.[Email]
    FROM [dbo].[Orders] o
    INNER JOIN [dbo].[Customers] c ON o.[CustomerId] = c.[CustomerId]
    WHERE o.[CustomerId] = @CustomerId
    ORDER BY o.[OrderDate] DESC;
END
GO
