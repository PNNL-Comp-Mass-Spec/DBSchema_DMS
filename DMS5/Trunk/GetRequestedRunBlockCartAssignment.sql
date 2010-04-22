/****** Object:  UserDefinedFunction [dbo].[GetRequestedRunBlockCartAssignment] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.GetRequestedRunBlockCartAssignment
/****************************************************
**
**	Desc: 
**  Returns cart assignment, or col assignment
**  for given requested run batch and block
**
**	Return value: cart or col (or '(mixed)')
**
**	Parameters: 
**
**	Auth:	grk
**	Date:	02/12/2010
**    
*****************************************************/
(
	@batchID INT,
	@block INT,
	@mode VARCHAR(24) = 'cart' -- 'col'
)
RETURNS varchar(64)
AS
	BEGIN
		declare @list varchar(6000)
		set @list = ''
		DECLARE @cart VARCHAR(512)
		DECLARE @col VARCHAR(256)

		SET @cart = ''
		SET @col = ''

		IF NOT (@batchID IS NULL OR @block IS NULL)
		BEGIN	
			DECLARE @hit INT 
			SET @hit = 0

			SELECT
			@cart = @cart + Cart + ' ',
			@col = @col + convert(varchar(12), isnull(Col, '')) + ' ',
			@hit = @hit + 1
			FROM
			(
			SELECT DISTINCT
			  T_LC_Cart.Cart_Name AS Cart,
			  T_Requested_Run.RDS_Cart_Col AS Col
			FROM
			  T_Requested_Run
			  INNER JOIN T_LC_Cart ON T_Requested_Run.RDS_Cart_ID = T_LC_Cart.ID
			WHERE
			  ( T_Requested_Run.RDS_BatchID = @batchID )
			  AND ( T_Requested_Run.RDS_Block = @block )
			) AS T

			IF @hit > 1
			BEGIN
				SET @cart = '(mixed)'
				SET @col = '(mixed)'
			END

		END

		RETURN CASE WHEN @mode = 'cart' THEN @cart ELSE @col END 
	END

GO
GRANT EXECUTE ON [dbo].[GetRequestedRunBlockCartAssignment] TO [DMS2_SP_User] AS [dbo]
GO
