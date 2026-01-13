CREATE PROCEDURE [dbo].[usp_AddCustomer]
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @Email NVARCHAR(100),
    @PhoneNumber NVARCHAR(20) = NULL,
    @CustomerId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [dbo].[Customers] ([FirstName], [LastName], [Email], [PhoneNumber])
    VALUES (@FirstName, @LastName, @Email, @PhoneNumber);

    SET @CustomerId = SCOPE_IDENTITY();
END
GO
