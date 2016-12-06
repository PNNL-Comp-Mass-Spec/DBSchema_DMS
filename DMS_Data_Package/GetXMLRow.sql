/****** Object:  UserDefinedFunction [dbo].[GetXMLRow] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.GetXMLRow
(
@Data_Package_ID INT,
@Type VARCHAR(64),
@ItemID VARCHAR(128)
)
RETURNS VARCHAR(512)
AS
	BEGIN
	RETURN  '<item pkg="' + CONVERT(VARCHAR(12), @Data_Package_ID) + '" type="' + @Type + '" id="' + @ItemID + '"/>'
	END

GO
GRANT VIEW DEFINITION ON [dbo].[GetXMLRow] TO [DDL_Viewer] AS [dbo]
GO
