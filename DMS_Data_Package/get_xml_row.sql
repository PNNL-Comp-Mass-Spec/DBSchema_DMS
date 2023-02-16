/****** Object:  UserDefinedFunction [dbo].[get_xml_row] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_xml_row]
(
    @data_Package_ID INT,
    @type VARCHAR(64),
    @itemID VARCHAR(128)
)
RETURNS VARCHAR(512)
AS
    BEGIN
    RETURN  '<item pkg="' + CONVERT(VARCHAR(12), @Data_Package_ID) + '" type="' + @Type + '" id="' + @ItemID + '"/>'
    END

GO
GRANT VIEW DEFINITION ON [dbo].[get_xml_row] TO [DDL_Viewer] AS [dbo]
GO
